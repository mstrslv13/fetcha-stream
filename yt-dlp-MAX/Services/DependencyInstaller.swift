import Foundation
import AppKit

@MainActor
final class DependencyInstaller {
    
    // MARK: - Properties
    private let processExecutor = ProcessExecutor()
    private let logger = PersistentDebugLogger.shared
    private let dependencyManager = DependencyManager.shared
    
    typealias ProgressHandler = (OnboardingCoordinator.InstallationProgress) -> Void
    
    // MARK: - Public Methods
    
    func installHomebrew(progressHandler: @escaping ProgressHandler) async throws {
        logger.log("Starting Homebrew installation", level: .info)
        
        // First check if it's already installed
        let homebrewState = await dependencyManager.checkHomebrew()
        if homebrewState.isInstalled {
            logger.log("Homebrew already installed", level: .info)
            progressHandler(OnboardingCoordinator.InstallationProgress(
                currentTask: "Homebrew already installed",
                progress: 1.0,
                logs: ["Homebrew is already installed at \(homebrewState.path ?? "unknown")"]
            ))
            return
        }
        
        progressHandler(OnboardingCoordinator.InstallationProgress(
            currentTask: "Preparing Homebrew installation",
            progress: 0.1,
            estimatedTimeRemaining: 120,
            logs: ["Downloading Homebrew installer...", "You may be prompted for your password..."]
        ))
        
        // Download and run the Homebrew install script
        let installScript = """
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        """
        
        do {
            // Use AppleScript to run with admin privileges
            let appleScript = """
            do shell script "\(installScript)" with administrator privileges
            """
            
            progressHandler(OnboardingCoordinator.InstallationProgress(
                currentTask: "Installing Homebrew (this may take a few minutes)",
                progress: 0.3,
                estimatedTimeRemaining: 90,
                logs: ["Running Homebrew installer...", "Please enter your password when prompted..."],
                isIndeterminate: true
            ))
            
            // Execute with admin privileges
            try await executeWithPrivileges(script: appleScript, progressHandler: progressHandler)
            
            // Configure PATH for Apple Silicon Macs
            if ProcessInfo.processInfo.machineHardwareName?.contains("arm64") ?? false {
                progressHandler(OnboardingCoordinator.InstallationProgress(
                    currentTask: "Configuring Homebrew paths",
                    progress: 0.8,
                    logs: ["Setting up Homebrew in your shell environment..."]
                ))
                
                await configureHomebrewPath()
            }
            
            progressHandler(OnboardingCoordinator.InstallationProgress(
                currentTask: "Homebrew installed successfully",
                progress: 1.0,
                logs: ["Homebrew has been installed successfully!"]
            ))
            
            // Clear cache to force recheck
            dependencyManager.clearCache()
            
        } catch {
            logger.log("Homebrew installation failed: \(error)", level: .error)
            throw OnboardingCoordinator.OnboardingError.installationFailed("Homebrew installation failed: \(error.localizedDescription)")
        }
    }
    
    func installYTDLP(progressHandler: @escaping ProgressHandler) async throws {
        logger.log("Starting yt-dlp installation", level: .info)
        
        // Check if already installed
        let ytdlpState = await dependencyManager.checkYTDLP()
        if ytdlpState.isInstalled {
            logger.log("yt-dlp already installed", level: .info)
            progressHandler(OnboardingCoordinator.InstallationProgress(
                currentTask: "yt-dlp already installed",
                progress: 1.0,
                logs: ["yt-dlp is already installed at \(ytdlpState.path ?? "unknown")"]
            ))
            return
        }
        
        // Find brew path
        guard let brewPath = findBrewPath() else {
            logger.log("Homebrew not found, cannot install yt-dlp", level: .error)
            throw OnboardingCoordinator.OnboardingError.installationFailed("Homebrew is required to install yt-dlp")
        }
        
        progressHandler(OnboardingCoordinator.InstallationProgress(
            currentTask: "Installing yt-dlp",
            progress: 0.1,
            estimatedTimeRemaining: 30,
            logs: ["Running: brew install yt-dlp", "This downloads the latest version..."]
        ))
        
        do {
            // Install yt-dlp via Homebrew
            let result = try await processExecutor.execute(
                executablePath: brewPath,
                arguments: ["install", "yt-dlp"],
                timeout: 120,
                environment: getBrewEnvironment()
            )
            
            if result.exitCode != 0 {
                // Check if it's already installed (exit code might be 1 for "already installed")
                if result.output.contains("already installed") {
                    progressHandler(OnboardingCoordinator.InstallationProgress(
                        currentTask: "yt-dlp already installed",
                        progress: 1.0,
                        logs: ["yt-dlp was already installed via Homebrew"]
                    ))
                    dependencyManager.clearCache()
                    return
                }
                
                logger.log("yt-dlp installation failed: \(result.error)", level: .error)
                throw OnboardingCoordinator.OnboardingError.installationFailed("Failed to install yt-dlp: \(result.error)")
            }
            
            progressHandler(OnboardingCoordinator.InstallationProgress(
                currentTask: "yt-dlp installed successfully",
                progress: 1.0,
                logs: ["yt-dlp has been installed successfully!", "You can now download videos from 1000+ sites"]
            ))
            
            // Clear cache to force recheck
            dependencyManager.clearCache()
            
        } catch let error as OnboardingCoordinator.OnboardingError {
            throw error
        } catch {
            logger.log("yt-dlp installation error: \(error)", level: .error)
            throw OnboardingCoordinator.OnboardingError.installationFailed("Failed to install yt-dlp: \(error.localizedDescription)")
        }
    }
    
    func installFFmpeg(progressHandler: @escaping ProgressHandler) async throws {
        logger.log("Starting ffmpeg installation", level: .info)
        
        // Check if already installed
        let ffmpegState = await dependencyManager.checkFFmpeg()
        if ffmpegState.isInstalled {
            logger.log("ffmpeg already installed", level: .info)
            progressHandler(OnboardingCoordinator.InstallationProgress(
                currentTask: "ffmpeg already installed",
                progress: 1.0,
                logs: ["ffmpeg is already installed at \(ffmpegState.path ?? "unknown")"]
            ))
            return
        }
        
        // Find brew path
        guard let brewPath = findBrewPath() else {
            logger.log("Homebrew not found, cannot install ffmpeg", level: .error)
            throw OnboardingCoordinator.OnboardingError.installationFailed("Homebrew is required to install ffmpeg")
        }
        
        progressHandler(OnboardingCoordinator.InstallationProgress(
            currentTask: "Installing ffmpeg (this may take a few minutes)",
            progress: 0.1,
            estimatedTimeRemaining: 90,
            logs: ["Running: brew install ffmpeg", "ffmpeg is a large package, please be patient..."],
            isIndeterminate: true
        ))
        
        do {
            // Install ffmpeg via Homebrew
            let result = try await processExecutor.execute(
                executablePath: brewPath,
                arguments: ["install", "ffmpeg"],
                timeout: 300, // ffmpeg can take longer to install
                environment: getBrewEnvironment()
            )
            
            if result.exitCode != 0 {
                // Check if it's already installed
                if result.output.contains("already installed") {
                    progressHandler(OnboardingCoordinator.InstallationProgress(
                        currentTask: "ffmpeg already installed",
                        progress: 1.0,
                        logs: ["ffmpeg was already installed via Homebrew"]
                    ))
                    dependencyManager.clearCache()
                    return
                }
                
                logger.log("ffmpeg installation failed: \(result.error)", level: .error)
                
                // ffmpeg is optional, so we can continue even if it fails
                progressHandler(OnboardingCoordinator.InstallationProgress(
                    currentTask: "ffmpeg installation failed (optional)",
                    progress: 1.0,
                    logs: ["ffmpeg installation failed but it's optional", "You can still download videos without it"]
                ))
                return
            }
            
            progressHandler(OnboardingCoordinator.InstallationProgress(
                currentTask: "ffmpeg installed successfully",
                progress: 1.0,
                logs: ["ffmpeg has been installed successfully!", "Video/audio merging is now available"]
            ))
            
            // Clear cache to force recheck
            dependencyManager.clearCache()
            
        } catch {
            // ffmpeg is optional, log the error but don't throw
            logger.log("ffmpeg installation error (non-fatal): \(error)", level: .warning)
            progressHandler(OnboardingCoordinator.InstallationProgress(
                currentTask: "ffmpeg installation skipped",
                progress: 1.0,
                logs: ["ffmpeg installation was skipped", "You can install it later if needed"]
            ))
        }
    }
    
    // MARK: - Helper Methods
    
    private func findBrewPath() -> String? {
        let paths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                logger.log("Found brew at: \(path)", level: .info)
                return path
            }
        }
        logger.log("Brew not found in standard locations", level: .warning)
        return nil
    }
    
    private func getBrewEnvironment() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        
        // Ensure Homebrew paths are in PATH
        if let existingPath = environment["PATH"] {
            environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:\(existingPath)"
        } else {
            environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        }
        
        // Set Homebrew environment variables
        environment["HOMEBREW_NO_AUTO_UPDATE"] = "1" // Don't auto-update during install
        environment["HOMEBREW_NO_ANALYTICS"] = "1"   // Respect privacy
        
        return environment
    }
    
    private func executeWithPrivileges(script: String, progressHandler: @escaping ProgressHandler) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async { [weak self] in
                var error: NSDictionary?
                if let scriptObject = NSAppleScript(source: script) {
                    let result = scriptObject.executeAndReturnError(&error)
                    
                    if let error = error {
                        let errorMessage = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown error"
                        self?.logger.log("AppleScript execution failed: \(errorMessage)", level: .error)
                        
                        if errorMessage.contains("User canceled") || errorMessage.contains("cancelled") {
                            continuation.resume(throwing: OnboardingCoordinator.OnboardingError.cancelled)
                        } else {
                            continuation.resume(throwing: OnboardingCoordinator.OnboardingError.permissionDenied)
                        }
                    } else {
                        self?.logger.log("AppleScript executed successfully", level: .info)
                        continuation.resume(returning: ())
                    }
                } else {
                    self?.logger.log("Failed to create AppleScript", level: .error)
                    continuation.resume(throwing: OnboardingCoordinator.OnboardingError.installationFailed("Failed to create installation script"))
                }
            }
        }
    }
    
    private func configureHomebrewPath() async {
        logger.log("Configuring Homebrew PATH for Apple Silicon", level: .info)
        
        // Shell configuration files to update
        let shellConfigFiles = [
            "~/.zshrc",        // Default shell on modern macOS
            "~/.bash_profile", // Bash users
            "~/.profile"       // Generic profile
        ]
        
        let homebrewPathLine = """
        
        # Added by Fetcha for Homebrew support
        eval "$(/opt/homebrew/bin/brew shellenv)"
        """
        
        for configFile in shellConfigFiles {
            let expandedPath = NSString(string: configFile).expandingTildeInPath
            
            // Create file if it doesn't exist
            if !FileManager.default.fileExists(atPath: expandedPath) {
                FileManager.default.createFile(atPath: expandedPath, contents: nil)
            }
            
            // Read existing content
            if var content = try? String(contentsOfFile: expandedPath, encoding: .utf8) {
                // Check if Homebrew path is already configured
                if !content.contains("/opt/homebrew/bin/brew shellenv") {
                    content += homebrewPathLine
                    
                    do {
                        try content.write(toFile: expandedPath, atomically: true, encoding: .utf8)
                        logger.log("Updated \(configFile) with Homebrew path", level: .info)
                    } catch {
                        logger.log("Failed to update \(configFile): \(error)", level: .warning)
                    }
                }
            }
        }
        
        // Also update current environment for immediate use
        setenv("PATH", "/opt/homebrew/bin:/usr/local/bin:\(ProcessInfo.processInfo.environment["PATH"] ?? "")", 1)
    }
    
    // MARK: - Network Check
    
    func isNetworkAvailable() async -> Bool {
        // Simple network check by trying to reach GitHub
        do {
            let url = URL(string: "https://raw.githubusercontent.com")!
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            logger.log("Network check failed: \(error)", level: .info)
        }
        return false
    }
}

// MARK: - ProcessInfo Extension

extension ProcessInfo {
    var machineHardwareName: String? {
        var sysinfo = utsname()
        let result = uname(&sysinfo)
        
        guard result == EXIT_SUCCESS else { return nil }
        
        let machine = withUnsafePointer(to: &sysinfo.machine) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) { machine in
                String(cString: machine)
            }
        }
        
        return machine
    }
}