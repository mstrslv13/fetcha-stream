import Foundation
import SwiftUI
import Combine

@MainActor
final class OnboardingCoordinator: ObservableObject {
    
    // MARK: - Singleton
    static let shared = OnboardingCoordinator()
    
    // MARK: - Published Properties
    @Published var isOnboardingRequired = false
    @Published var currentStep: OnboardingStep = .welcome
    @Published var dependencies: DependencyStatus?
    @Published var installationProgress: InstallationProgress?
    @Published var isInstalling = false
    @Published var error: OnboardingError?
    
    // MARK: - Dependencies
    private let dependencyManager = DependencyManager.shared
    private let installer = DependencyInstaller()
    private let processExecutor = ProcessExecutor()
    private let preferences = AppPreferences.shared
    private let logger = PersistentDebugLogger.shared
    
    // MARK: - Types
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case dependencyCheck = 1
        case installation = 2
        case manualSetup = 3
        case cookiePermissions = 4
        case complete = 5
        
        var progress: Double {
            return Double(self.rawValue) / Double(OnboardingStep.allCases.count - 1)
        }
        
        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .dependencyCheck: return "Checking Requirements"
            case .installation: return "Installing Components"
            case .manualSetup: return "Manual Setup"
            case .cookiePermissions: return "Browser Integration"
            case .complete: return "All Set!"
            }
        }
    }
    
    struct DependencyStatus {
        let homebrew: DependencyState
        let ytdlp: DependencyState
        let ffmpeg: DependencyState
        
        var allSatisfied: Bool {
            ytdlp.isInstalled && ffmpeg.isInstalled
        }
        
        var requiredMissing: Bool {
            !ytdlp.isInstalled
        }
        
        var optionalMissing: Bool {
            !ffmpeg.isInstalled
        }
        
        var needsInstallation: Bool {
            requiredMissing || optionalMissing
        }
    }
    
    struct DependencyState {
        let isInstalled: Bool
        let path: String?
        let version: String?
        let isRequired: Bool
        let displayName: String
        let description: String
    }
    
    struct InstallationProgress {
        let currentTask: String
        let progress: Double
        let estimatedTimeRemaining: TimeInterval?
        let logs: [String]
        let isIndeterminate: Bool
        
        init(currentTask: String, progress: Double = 0, estimatedTimeRemaining: TimeInterval? = nil, logs: [String] = [], isIndeterminate: Bool = false) {
            self.currentTask = currentTask
            self.progress = progress
            self.estimatedTimeRemaining = estimatedTimeRemaining
            self.logs = logs
            self.isIndeterminate = isIndeterminate
        }
    }
    
    enum OnboardingError: LocalizedError {
        case installationFailed(String)
        case permissionDenied
        case networkError
        case cancelled
        case verificationFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .installationFailed(let reason):
                return "Installation failed: \(reason)"
            case .permissionDenied:
                return "Administrator permission is required to install dependencies"
            case .networkError:
                return "A network connection is required to download components"
            case .cancelled:
                return "Installation was cancelled"
            case .verificationFailed(let reason):
                return "Could not verify installation: \(reason)"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .installationFailed:
                return "Try installing manually or check your internet connection"
            case .permissionDenied:
                return "Please enter your password when prompted to continue"
            case .networkError:
                return "Check your internet connection and try again"
            case .cancelled:
                return "You can restart the installation at any time"
            case .verificationFailed:
                return "Try restarting the app or install the components manually"
            }
        }
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        logger.log("OnboardingCoordinator initialized", level: .info)
    }
    
    // MARK: - Public Methods
    
    func checkIfOnboardingNeeded() async {
        logger.log("Checking if onboarding is needed", level: .info)
        
        // Check if first launch
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "HasCompletedOnboarding")
        let onboardingVersion = UserDefaults.standard.integer(forKey: "OnboardingVersion")
        let currentOnboardingVersion = 1
        
        // Check dependencies
        let status = await checkDependencies()
        self.dependencies = status
        
        // Determine if onboarding is needed
        if !hasCompletedOnboarding || onboardingVersion < currentOnboardingVersion {
            logger.log("First launch or outdated onboarding detected", level: .info)
            isOnboardingRequired = true
            currentStep = .welcome
        } else if status.requiredMissing {
            logger.log("Required dependencies missing", level: .warning)
            isOnboardingRequired = true
            currentStep = .dependencyCheck
        } else if status.optionalMissing && !UserDefaults.standard.bool(forKey: "HasDismissedOptionalDependencies") {
            logger.log("Optional dependencies missing", level: .info)
            // Show onboarding for optional dependencies
            isOnboardingRequired = true
            currentStep = .dependencyCheck
        } else {
            logger.log("No onboarding needed", level: .info)
            isOnboardingRequired = false
        }
    }
    
    func checkDependencies() async -> DependencyStatus {
        logger.log("Checking all dependencies", level: .info)
        
        async let homebrew = dependencyManager.checkHomebrew()
        async let ytdlp = dependencyManager.checkYTDLP()
        async let ffmpeg = dependencyManager.checkFFmpeg()
        
        return await DependencyStatus(
            homebrew: homebrew,
            ytdlp: ytdlp,
            ffmpeg: ffmpeg
        )
    }
    
    func startAutomatedInstallation() async {
        logger.log("Starting automated installation", level: .info)
        isInstalling = true
        error = nil
        currentStep = .installation
        
        do {
            // Check for Homebrew first
            if !(dependencies?.homebrew.isInstalled ?? false) {
                installationProgress = InstallationProgress(
                    currentTask: "Installing Homebrew package manager",
                    progress: 0.1,
                    estimatedTimeRemaining: 120,
                    logs: ["Preparing to install Homebrew...", "This may take 2-3 minutes..."]
                )
                
                try await installer.installHomebrew { [weak self] progress in
                    DispatchQueue.main.async {
                        self?.installationProgress = progress
                    }
                }
                
                logger.log("Homebrew installed successfully", level: .success)
            }
            
            // Install yt-dlp
            if !(dependencies?.ytdlp.isInstalled ?? false) {
                installationProgress = InstallationProgress(
                    currentTask: "Installing yt-dlp video downloader",
                    progress: 0.5,
                    estimatedTimeRemaining: 30,
                    logs: ["Installing yt-dlp via Homebrew..."]
                )
                
                try await installer.installYTDLP { [weak self] progress in
                    DispatchQueue.main.async {
                        self?.installationProgress = progress
                    }
                }
                
                logger.log("yt-dlp installed successfully", level: .success)
            }
            
            // Install ffmpeg (optional but recommended)
            if !(dependencies?.ffmpeg.isInstalled ?? false) {
                installationProgress = InstallationProgress(
                    currentTask: "Installing ffmpeg for video processing",
                    progress: 0.8,
                    estimatedTimeRemaining: 60,
                    logs: ["Installing ffmpeg via Homebrew...", "This enables video/audio merging..."]
                )
                
                try await installer.installFFmpeg { [weak self] progress in
                    DispatchQueue.main.async {
                        self?.installationProgress = progress
                    }
                }
                
                logger.log("ffmpeg installed successfully", level: .success)
            }
            
            // Verify installation
            installationProgress = InstallationProgress(
                currentTask: "Verifying installation",
                progress: 0.95,
                logs: ["Checking installed components..."],
                isIndeterminate: true
            )
            
            let finalStatus = await checkDependencies()
            self.dependencies = finalStatus
            
            if finalStatus.allSatisfied {
                logger.log("All dependencies installed and verified", level: .success)
                currentStep = .cookiePermissions
            } else if finalStatus.ytdlp.isInstalled {
                // At least the required dependency is installed
                logger.log("Required dependencies installed, optional missing", level: .warning)
                currentStep = .cookiePermissions
            } else {
                throw OnboardingError.verificationFailed("Could not verify yt-dlp installation")
            }
            
        } catch let onboardingError as OnboardingError {
            logger.log("Installation failed: \(onboardingError.localizedDescription)", level: .error)
            self.error = onboardingError
            currentStep = .manualSetup
        } catch {
            logger.log("Installation failed with unexpected error: \(error)", level: .error)
            self.error = .installationFailed(error.localizedDescription)
            currentStep = .manualSetup
        }
        
        isInstalling = false
    }
    
    func selectManualPaths(ytdlpPath: String?, ffmpegPath: String?) {
        logger.log("Manual paths selected - yt-dlp: \(ytdlpPath ?? "none"), ffmpeg: \(ffmpegPath ?? "none")", level: .info)
        
        // Save manual paths to preferences
        if let ytdlp = ytdlpPath {
            UserDefaults.standard.set(ytdlp, forKey: "ManualYtdlpPath")
        }
        if let ffmpeg = ffmpegPath {
            preferences.ffmpegPath = ffmpeg
        }
        
        // Proceed to next step
        currentStep = .cookiePermissions
    }
    
    func skipOptionalDependencies() {
        logger.log("User skipped optional dependencies", level: .info)
        UserDefaults.standard.set(true, forKey: "HasDismissedOptionalDependencies")
        currentStep = .cookiePermissions
    }
    
    func configureCookieSource(_ source: String) {
        logger.log("Cookie source configured: \(source)", level: .info)
        preferences.cookieSource = source
        completeOnboarding()
    }
    
    func completeOnboarding() {
        logger.log("Onboarding completed", level: .success)
        
        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "HasCompletedOnboarding")
        UserDefaults.standard.set(1, forKey: "OnboardingVersion")
        
        currentStep = .complete
        
        // Delay before dismissing
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            await MainActor.run {
                isOnboardingRequired = false
            }
        }
    }
    
    func retry() {
        logger.log("Retrying installation", level: .info)
        error = nil
        Task {
            await startAutomatedInstallation()
        }
    }
    
    func cancel() {
        logger.log("Onboarding cancelled", level: .warning)
        error = .cancelled
        isInstalling = false
        
        // If required dependencies are installed, allow proceeding
        if dependencies?.ytdlp.isInstalled == true {
            currentStep = .cookiePermissions
        } else {
            // Can't proceed without required dependencies
            isOnboardingRequired = false
        }
    }
    
    // MARK: - Navigation
    
    func goToNextStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex < OnboardingStep.allCases.count - 1 else { return }
        
        currentStep = OnboardingStep.allCases[currentIndex + 1]
        logger.log("Moving to step: \(currentStep.title)", level: .info)
    }
    
    func goToPreviousStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else { return }
        
        currentStep = OnboardingStep.allCases[currentIndex - 1]
        logger.log("Moving back to step: \(currentStep.title)", level: .info)
    }
}