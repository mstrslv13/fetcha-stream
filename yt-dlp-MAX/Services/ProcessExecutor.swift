import Foundation
import Combine

/// Handles execution and management of external processes
/// This class encapsulates all Process-related operations to reduce complexity in YTDLPService
@MainActor
final class ProcessExecutor: ObservableObject {
    
    // MARK: - Types
    
    struct ProcessResult {
        let output: String
        let error: String
        let exitCode: Int32
        let timedOut: Bool
    }
    
    enum ProcessError: LocalizedError {
        case executableNotFound(String)
        case processTimeout(String)
        case processFailed(exitCode: Int32, error: String)
        case invalidOutput
        
        var errorDescription: String? {
            switch self {
            case .executableNotFound(let path):
                return "Executable not found at: \(path)"
            case .processTimeout(let description):
                return "Process timed out: \(description)"
            case .processFailed(let code, let error):
                return "Process failed with exit code \(code): \(error)"
            case .invalidOutput:
                return "Process returned invalid output"
            }
        }
    }
    
    // MARK: - Properties
    
    private var activeProcesses: [UUID: Process] = [:]
    private let processQueue = DispatchQueue(label: "com.ytdlpmax.processexecutor", attributes: .concurrent)
    
    // MARK: - Public Methods
    
    /// Execute a process and return the result
    /// - Parameters:
    ///   - executablePath: Path to the executable
    ///   - arguments: Command line arguments
    ///   - timeout: Timeout in seconds (default: 30)
    ///   - environment: Environment variables (optional)
    /// - Returns: ProcessResult containing output, error, and exit code
    func execute(
        executablePath: String,
        arguments: [String],
        timeout: TimeInterval = 30,
        environment: [String: String]? = nil
    ) async throws -> ProcessResult {
        
        // Validate executable exists
        guard FileManager.default.fileExists(atPath: executablePath) else {
            throw ProcessError.executableNotFound(executablePath)
        }
        
        let process = Process()
        let processID = UUID()
        
        // Configure process
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        
        // Set up environment
        if let environment = environment {
            process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }
        }
        
        // Set up pipes
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Track active process
        await addActiveProcess(processID, process)
        
        // Start process with timeout
        let result = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ProcessResult, Error>) in
                processQueue.async {
                    do {
                        try process.run()
                        
                        // Set up timeout
                        let timeoutWorkItem = DispatchWorkItem { [weak self, weak process] in
                            guard let process = process, process.isRunning else { return }
                            
                            process.terminate()
                            Task {
                                await self?.removeActiveProcess(processID)
                            }
                            
                            continuation.resume(throwing: ProcessError.processTimeout("Operation exceeded \(timeout) seconds"))
                        }
                        
                        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)
                        
                        // Read output data
                        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                        
                        // Wait for process completion
                        process.waitUntilExit()
                        
                        // Cancel timeout if process completed
                        timeoutWorkItem.cancel()
                        
                        // Create result
                        let result = ProcessResult(
                            output: String(data: outputData, encoding: .utf8) ?? "",
                            error: String(data: errorData, encoding: .utf8) ?? "",
                            exitCode: process.terminationStatus,
                            timedOut: false
                        )
                        
                        Task {
                            await self.removeActiveProcess(processID)
                        }
                        
                        continuation.resume(returning: result)
                        
                    } catch {
                        Task {
                            await self.removeActiveProcess(processID)
                        }
                        continuation.resume(throwing: error)
                    }
                }
            }
        } onCancel: {
            Task {
                await self.terminateProcess(processID)
            }
        }
        
        // Check exit code
        if result.exitCode != 0 && !result.timedOut {
            throw ProcessError.processFailed(exitCode: result.exitCode, error: result.error)
        }
        
        return result
    }
    
    /// Execute a long-running process with progress updates
    /// - Parameters:
    ///   - executablePath: Path to the executable
    ///   - arguments: Command line arguments
    ///   - outputHandler: Closure called for each line of output
    ///   - errorHandler: Closure called for each line of error output
    ///   - timeout: Timeout in seconds (default: 600 for 10 minutes)
    /// - Returns: Process exit code
    @discardableResult
    func executeLongRunning(
        executablePath: String,
        arguments: [String],
        outputHandler: @escaping (String) -> Void,
        errorHandler: @escaping (String) -> Void,
        timeout: TimeInterval = 600
    ) async throws -> Int32 {
        
        // Validate executable exists
        guard FileManager.default.fileExists(atPath: executablePath) else {
            throw ProcessError.executableNotFound(executablePath)
        }
        
        let process = Process()
        let processID = UUID()
        
        // Configure process
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        
        // Set up pipes
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Set up output handlers
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            
            if let output = String(data: data, encoding: .utf8) {
                for line in output.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        outputHandler(trimmed)
                    }
                }
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            
            if let error = String(data: data, encoding: .utf8) {
                for line in error.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        errorHandler(trimmed)
                    }
                }
            }
        }
        
        // Track active process
        await addActiveProcess(processID, process)
        
        // Start process
        try process.run()
        
        // Set up timeout
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            
            if process.isRunning {
                await terminateProcess(processID)
                throw ProcessError.processTimeout("Download exceeded \(timeout) seconds")
            }
        }
        
        // Wait for completion
        await withCheckedContinuation { continuation in
            processQueue.async {
                process.waitUntilExit()
                continuation.resume()
            }
        }
        
        // Cancel timeout
        timeoutTask.cancel()
        
        // Clean up handlers
        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        
        // Remove from active processes
        await removeActiveProcess(processID)
        
        return process.terminationStatus
    }
    
    /// Terminate all active processes
    func terminateAll() async {
        let processes = await getActiveProcesses()
        for (id, _) in processes {
            await terminateProcess(id)
        }
    }
    
    // MARK: - Private Methods
    
    private func addActiveProcess(_ id: UUID, _ process: Process) async {
        activeProcesses[id] = process
    }
    
    private func removeActiveProcess(_ id: UUID) async {
        activeProcesses.removeValue(forKey: id)
    }
    
    private func getActiveProcesses() async -> [UUID: Process] {
        return activeProcesses
    }
    
    private func terminateProcess(_ id: UUID) async {
        guard let process = activeProcesses[id] else { return }
        
        if process.isRunning {
            process.terminate()
        }
        
        activeProcesses.removeValue(forKey: id)
    }
}

// MARK: - Process Extensions

extension Process {
    /// Clean up pipes to prevent resource leaks
    func cleanupPipes() {
        if let outputPipe = self.standardOutput as? Pipe {
            outputPipe.fileHandleForReading.readabilityHandler = nil
            try? outputPipe.fileHandleForReading.close()
        }
        
        if let errorPipe = self.standardError as? Pipe {
            errorPipe.fileHandleForReading.readabilityHandler = nil
            try? errorPipe.fileHandleForReading.close()
        }
        
        if let inputPipe = self.standardInput as? Pipe {
            try? inputPipe.fileHandleForWriting.close()
        }
    }
}