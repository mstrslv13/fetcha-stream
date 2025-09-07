import Foundation

@MainActor
final class DependencyManager {
    
    // MARK: - Singleton
    static let shared = DependencyManager()
    
    // MARK: - Properties
    private let processExecutor = ProcessExecutor()
    private let logger = PersistentDebugLogger.shared
    
    // Cache for dependency paths and versions
    private var cachedHomebrew: OnboardingCoordinator.DependencyState?
    private var cachedYTDLP: OnboardingCoordinator.DependencyState?
    private var cachedFFmpeg: OnboardingCoordinator.DependencyState?
    
    // MARK: - Initialization
    private init() {
        logger.log("DependencyManager initialized", level: .info)
    }
    
    // MARK: - Public Methods
    
    func checkHomebrew() async -> OnboardingCoordinator.DependencyState {
        // Return cached result if available
        if let cached = cachedHomebrew {
            return cached
        }
        
        logger.log("Checking for Homebrew installation", level: .info)
        
        let paths = [
            "/opt/homebrew/bin/brew",     // Apple Silicon
            "/usr/local/bin/brew",         // Intel Mac
            "/home/linuxbrew/.linuxbrew/bin/brew" // Linux (future support)
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                // Get version
                if let version = try? await getVersion(executablePath: path, argument: "--version") {
                    let cleanVersion = extractBrewVersion(from: version)
                    let state = OnboardingCoordinator.DependencyState(
                        isInstalled: true,
                        path: path,
                        version: cleanVersion,
                        isRequired: false,
                        displayName: "Homebrew",
                        description: "Package manager for macOS"
                    )
                    cachedHomebrew = state
                    logger.log("Homebrew found at \(path), version: \(cleanVersion)", level: .success)
                    return state
                }
            }
        }
        
        logger.log("Homebrew not found", level: .warning)
        let state = OnboardingCoordinator.DependencyState(
            isInstalled: false,
            path: nil,
            version: nil,
            isRequired: false,
            displayName: "Homebrew",
            description: "Package manager for macOS"
        )
        cachedHomebrew = state
        return state
    }
    
    func checkYTDLP() async -> OnboardingCoordinator.DependencyState {
        // Return cached result if available
        if let cached = cachedYTDLP {
            return cached
        }
        
        logger.log("Checking for yt-dlp installation", level: .info)
        
        // Check manual path first, then standard locations
        let manualPath = UserDefaults.standard.string(forKey: "ManualYtdlpPath")
        let paths = ([manualPath] + [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/usr/bin/yt-dlp",
            Bundle.main.path(forResource: "yt-dlp", ofType: nil, inDirectory: "bin"),
            "\(NSHomeDirectory())/bin/yt-dlp",
            "\(NSHomeDirectory())/.local/bin/yt-dlp"
        ]).compactMap { $0 }
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                if let version = try? await getVersion(executablePath: path, argument: "--version") {
                    let cleanVersion = version.trimmingCharacters(in: .whitespacesAndNewlines)
                    let state = OnboardingCoordinator.DependencyState(
                        isInstalled: true,
                        path: path,
                        version: cleanVersion,
                        isRequired: true,
                        displayName: "yt-dlp",
                        description: "Video download engine (required)"
                    )
                    cachedYTDLP = state
                    logger.log("yt-dlp found at \(path), version: \(cleanVersion)", level: .success)
                    return state
                }
            }
        }
        
        // Try using 'which' command as fallback
        if let path = await findUsingWhich(command: "yt-dlp") {
            if let version = try? await getVersion(executablePath: path, argument: "--version") {
                let cleanVersion = version.trimmingCharacters(in: .whitespacesAndNewlines)
                let state = OnboardingCoordinator.DependencyState(
                    isInstalled: true,
                    path: path,
                    version: cleanVersion,
                    isRequired: true,
                    displayName: "yt-dlp",
                    description: "Video download engine (required)"
                )
                cachedYTDLP = state
                logger.log("yt-dlp found via which at \(path), version: \(cleanVersion)", level: .success)
                return state
            }
        }
        
        logger.log("yt-dlp not found", level: .error)
        let state = OnboardingCoordinator.DependencyState(
            isInstalled: false,
            path: nil,
            version: nil,
            isRequired: true,
            displayName: "yt-dlp",
            description: "Video download engine (required)"
        )
        cachedYTDLP = state
        return state
    }
    
    func checkFFmpeg() async -> OnboardingCoordinator.DependencyState {
        // Return cached result if available
        if let cached = cachedFFmpeg {
            return cached
        }
        
        logger.log("Checking for ffmpeg installation", level: .info)
        
        // Check user preference path first
        let preferencePath = AppPreferences.shared.ffmpegPath.isEmpty ? nil : AppPreferences.shared.ffmpegPath
        let paths = ([preferencePath] + [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/usr/bin/ffmpeg",
            Bundle.main.path(forResource: "ffmpeg", ofType: nil, inDirectory: "bin")
        ]).compactMap { $0 }
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                if let version = try? await getVersion(executablePath: path, argument: "-version") {
                    let cleanVersion = extractFFmpegVersion(from: version)
                    let state = OnboardingCoordinator.DependencyState(
                        isInstalled: true,
                        path: path,
                        version: cleanVersion,
                        isRequired: false,
                        displayName: "ffmpeg",
                        description: "Video processing (recommended for merging)"
                    )
                    cachedFFmpeg = state
                    logger.log("ffmpeg found at \(path), version: \(cleanVersion)", level: .success)
                    return state
                }
            }
        }
        
        // Try using 'which' command as fallback
        if let path = await findUsingWhich(command: "ffmpeg") {
            if let version = try? await getVersion(executablePath: path, argument: "-version") {
                let cleanVersion = extractFFmpegVersion(from: version)
                let state = OnboardingCoordinator.DependencyState(
                    isInstalled: true,
                    path: path,
                    version: cleanVersion,
                    isRequired: false,
                    displayName: "ffmpeg",
                    description: "Video processing (recommended for merging)"
                )
                cachedFFmpeg = state
                logger.log("ffmpeg found via which at \(path), version: \(cleanVersion)", level: .success)
                return state
            }
        }
        
        logger.log("ffmpeg not found", level: .warning)
        let state = OnboardingCoordinator.DependencyState(
            isInstalled: false,
            path: nil,
            version: nil,
            isRequired: false,
            displayName: "ffmpeg",
            description: "Video processing (recommended for merging)"
        )
        cachedFFmpeg = state
        return state
    }
    
    func clearCache() {
        logger.log("Clearing dependency cache", level: .info)
        cachedHomebrew = nil
        cachedYTDLP = nil
        cachedFFmpeg = nil
    }
    
    // MARK: - Helper Methods
    
    func findBinary(name: String) -> String? {
        logger.log("Looking for binary: \(name)", level: .info)
        
        // First check for bundled version in app Resources
        if let bundledPath = Bundle.main.path(forResource: name, ofType: nil, inDirectory: "bin") {
            if FileManager.default.fileExists(atPath: bundledPath) {
                logger.log("Using bundled \(name) at \(bundledPath)", level: .success)
                return bundledPath
            }
        }
        
        let possiblePaths = [
            "/opt/homebrew/bin/\(name)",        // Homebrew on Apple Silicon
            "/usr/local/bin/\(name)",           // Homebrew on Intel
            "/usr/bin/\(name)",                  // System install
            "/opt/local/bin/\(name)",           // MacPorts
            "\(NSHomeDirectory())/bin/\(name)", // User's home bin directory
            "\(NSHomeDirectory())/.local/bin/\(name)" // Python pip user install
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                logger.log("Found \(name) at: \(path)", level: .success)
                return path
            }
        }
        
        // Try using 'which' command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    logger.log("Found \(name) via which: \(path)", level: .success)
                    return path
                }
            }
        } catch {
            logger.log("Failed to find \(name): \(error)", level: .warning)
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    private func getVersion(executablePath: String, argument: String) async throws -> String {
        let result = try await processExecutor.execute(
            executablePath: executablePath,
            arguments: [argument],
            timeout: 5
        )
        
        if result.exitCode == 0 {
            return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            throw ProcessExecutor.ProcessError.processFailed(exitCode: result.exitCode, error: result.error)
        }
    }
    
    private func findUsingWhich(command: String) async -> String? {
        do {
            let result = try await processExecutor.execute(
                executablePath: "/usr/bin/which",
                arguments: [command],
                timeout: 2
            )
            
            if result.exitCode == 0 {
                let path = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
                return path.isEmpty ? nil : path
            }
        } catch {
            logger.log("which command failed for \(command): \(error)", level: .info)
        }
        return nil
    }
    
    private func extractBrewVersion(from output: String) -> String {
        // Homebrew outputs something like: "Homebrew 4.1.0"
        let lines = output.components(separatedBy: .newlines)
        if let firstLine = lines.first {
            let components = firstLine.components(separatedBy: " ")
            if components.count >= 2 {
                return components[1]
            }
        }
        return output.components(separatedBy: .newlines).first ?? "Unknown"
    }
    
    private func extractFFmpegVersion(from output: String) -> String {
        // ffmpeg outputs something like: "ffmpeg version 6.0 Copyright (c) 2000-2023..."
        // We want to extract just "6.0"
        let pattern = #"ffmpeg version ([\d.]+)"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(output.startIndex..., in: output)
            if let match = regex.firstMatch(in: output, options: [], range: range) {
                if let versionRange = Range(match.range(at: 1), in: output) {
                    return String(output[versionRange])
                }
            }
        }
        
        // Fallback: just get the first line
        return output.components(separatedBy: .newlines).first ?? "Unknown"
    }
}