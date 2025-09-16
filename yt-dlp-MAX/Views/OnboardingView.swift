import SwiftUI
import AppKit

struct OnboardingView: View {
    @StateObject private var coordinator = OnboardingCoordinator.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showManualPathPicker = false
    @State private var manualYtdlpPath = ""
    @State private var manualFfmpegPath = ""
    @State private var selectedYtdlpURL: URL?
    @State private var selectedFfmpegURL: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            OnboardingProgressBar(currentStep: coordinator.currentStep)
                .padding(.horizontal, 30)
                .padding(.top, 20)
            
            // Main content
            Group {
                switch coordinator.currentStep {
                case .welcome:
                    WelcomeStepView(coordinator: coordinator)
                    
                case .dependencyCheck:
                    DependencyCheckView(coordinator: coordinator)
                    
                case .installation:
                    InstallationProgressView(coordinator: coordinator)
                    
                case .manualSetup:
                    ManualSetupView(
                        coordinator: coordinator,
                        ytdlpPath: $manualYtdlpPath,
                        ffmpegPath: $manualFfmpegPath,
                        selectedYtdlpURL: $selectedYtdlpURL,
                        selectedFfmpegURL: $selectedFfmpegURL
                    )
                    
                case .cookiePermissions:
                    CookiePermissionsView(coordinator: coordinator)
                    
                case .complete:
                    CompletionView(coordinator: coordinator)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.3), value: coordinator.currentStep)
        }
        .frame(width: 700, height: 500)
        .background(VisualEffectBackground())
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Use system icon or NSApp icon
            if let appIcon = NSApplication.shared.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
            } else {
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.accentColor)
                    .frame(width: 100, height: 100)
            }
            
            Text("Welcome to Fetcha")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Quick setup to get you started")
                .font(.title3)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(
                    icon: "checkmark.circle.fill",
                    title: "Check dependencies",
                    description: "Verify yt-dlp and ffmpeg installation"
                )
                
                FeatureRow(
                    icon: "arrow.down.circle.fill",
                    title: "Install if needed",
                    description: "Automatic setup via Homebrew"
                )
                
                FeatureRow(
                    icon: "play.circle.fill",
                    title: "Start downloading",
                    description: "Begin using Fetcha immediately"
                )
            }
            .padding(.horizontal, 60)
            
            Spacer()
            
            NavigationButtonBar(
                coordinator: coordinator,
                showBack: false,
                showCancel: true,
                nextTitle: "Get Started",
                nextAction: {
                    coordinator.currentStep = .dependencyCheck
                    Task {
                        coordinator.dependencies = await coordinator.checkDependencies()
                    }
                }
            )
        }
    }
}

// MARK: - Dependency Check

struct DependencyCheckView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var isChecking = true
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Checking Requirements")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            if isChecking {
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                    
                    Text("Scanning your system...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if let deps = coordinator.dependencies {
                VStack(alignment: .leading, spacing: 20) {
                    DependencyRow(
                        name: "Homebrew",
                        status: deps.homebrew,
                        description: "Package manager for macOS"
                    )
                    
                    DependencyRow(
                        name: "yt-dlp",
                        status: deps.ytdlp,
                        description: "Video download engine (required)"
                    )
                    
                    DependencyRow(
                        name: "ffmpeg",
                        status: deps.ffmpeg,
                        description: "Video processing (recommended)"
                    )
                }
                .padding(.horizontal, 60)
                .frame(maxHeight: .infinity)
                
                // Status message
                Group {
                    if deps.allSatisfied {
                        Label("All dependencies are installed!", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.headline)
                    } else if deps.requiredMissing {
                        Label("Required components need to be installed", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.headline)
                    } else if deps.optionalMissing {
                        Label("Optional components are missing", systemImage: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.headline)
                    }
                }
                .padding(.bottom, 20)
                
                // Action buttons
                HStack(spacing: 15) {
                    if deps.needsInstallation {
                        Button("Select Manually...") {
                            coordinator.currentStep = .manualSetup
                        }
                        .controlSize(.large)
                        
                        if deps.optionalMissing && !deps.requiredMissing {
                            Button("Skip Optional") {
                                coordinator.skipOptionalDependencies()
                            }
                            .controlSize(.large)
                        }
                        
                        NavigationButtonBar(
                            coordinator: coordinator,
                            nextTitle: "Install Automatically",
                            nextAction: {
                                Task {
                                    await coordinator.startAutomatedInstallation()
                                }
                            }
                        )
                    } else {
                        NavigationButtonBar(
                            coordinator: coordinator,
                            nextTitle: "Continue",
                            nextAction: {
                                coordinator.currentStep = .cookiePermissions
                            }
                        )
                    }
                }
            }
        }
        .task {
            // Add a small delay for better UX
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isChecking = false
        }
    }
}

// MARK: - Installation Progress

struct InstallationProgressView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Installing Components")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            if let progress = coordinator.installationProgress {
                VStack(alignment: .leading, spacing: 20) {
                    // Current task
                    Text(progress.currentTask)
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    // Progress bar
                    if progress.isIndeterminate {
                        ProgressView()
                            .progressViewStyle(.linear)
                            .controlSize(.regular)
                    } else {
                        ProgressView(value: progress.progress)
                            .progressViewStyle(.linear)
                    }
                    
                    // Time remaining
                    if let timeRemaining = progress.estimatedTimeRemaining {
                        Text("Estimated time: \(formatTime(timeRemaining))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Installation log
                    GroupBox {
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 5) {
                                    ForEach(Array(progress.logs.enumerated()), id: \.offset) { index, log in
                                        Text(log)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                            .id(index)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .onChange(of: progress.logs.count) { oldValue, newValue in
                                withAnimation {
                                    proxy.scrollTo(newValue - 1, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .frame(height: 150)
                }
                .padding(.horizontal, 60)
                .frame(maxHeight: .infinity)
            }
            
            // Error handling
            if let error = coordinator.error {
                VStack(spacing: 15) {
                    Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.headline)
                    
                    if let recovery = error.recoverySuggestion {
                        Text(recovery)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 15) {
                        Button("Try Manual Setup") {
                            coordinator.currentStep = .manualSetup
                        }
                        .controlSize(.large)
                        
                        Button("Retry") {
                            coordinator.retry()
                        }
                        .controlSize(.large)
                        .keyboardShortcut(.defaultAction)
                    }
                }
                .padding(20)
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 60)
            }
            
            Spacer()
            
            // Add cancel button during installation
            if coordinator.isInstalling && coordinator.error == nil {
                NavigationButtonBar(
                    coordinator: coordinator,
                    showBack: false,
                    showNext: false,
                    showCancel: true,
                    nextTitle: "",
                    nextAction: {}
                )
            }
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds)) seconds"
        } else {
            let minutes = Int(seconds / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
}

// MARK: - Manual Setup

struct ManualSetupView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Binding var ytdlpPath: String
    @Binding var ffmpegPath: String
    @Binding var selectedYtdlpURL: URL?
    @Binding var selectedFfmpegURL: URL?
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Manual Setup")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Text("Select the locations of the required components")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 25) {
                // yt-dlp path
                VStack(alignment: .leading, spacing: 10) {
                    Label("yt-dlp location (required)", systemImage: "terminal.fill")
                        .font(.headline)
                    
                    HStack {
                        TextField("Path to yt-dlp", text: $ytdlpPath)
                            .textFieldStyle(.roundedBorder)
                            .disabled(true)
                        
                        Button("Browse...") {
                            selectFile(for: "yt-dlp") { url in
                                selectedYtdlpURL = url
                                ytdlpPath = url.path
                            }
                        }
                    }
                    
                    Text("Download from: https://github.com/yt-dlp/yt-dlp/releases")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // ffmpeg path
                VStack(alignment: .leading, spacing: 10) {
                    Label("ffmpeg location (optional)", systemImage: "film.fill")
                        .font(.headline)
                    
                    HStack {
                        TextField("Path to ffmpeg", text: $ffmpegPath)
                            .textFieldStyle(.roundedBorder)
                            .disabled(true)
                        
                        Button("Browse...") {
                            selectFile(for: "ffmpeg") { url in
                                selectedFfmpegURL = url
                                ffmpegPath = url.path
                            }
                        }
                    }
                    
                    Text("Download from: https://ffmpeg.org/download.html")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 60)
            .frame(maxHeight: .infinity)
            
            // Help text
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Installation Help", systemImage: "questionmark.circle")
                        .font(.headline)
                    
                    Text("1. Download the binaries from the links above")
                    Text("2. Move them to a location like /usr/local/bin/")
                    Text("3. Or install via Terminal: brew install yt-dlp ffmpeg")
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 60)
            
            NavigationButtonBar(
                coordinator: coordinator,
                nextTitle: "Continue",
                nextAction: {
                    coordinator.selectManualPaths(
                        ytdlpPath: ytdlpPath.isEmpty ? nil : ytdlpPath,
                        ffmpegPath: ffmpegPath.isEmpty ? nil : ffmpegPath
                    )
                },
                nextDisabled: ytdlpPath.isEmpty
            )
        }
    }
    
    private func selectFile(for binary: String, completion: @escaping (URL) -> Void) {
        let panel = NSOpenPanel()
        panel.title = "Select \(binary)"
        panel.prompt = "Select"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: "/usr/local/bin")
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                completion(url)
            }
        }
    }
}

// MARK: - Cookie Permissions

struct CookiePermissionsView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var cookieSource = "none"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Browser Integration")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 30)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Fetcha can use your browser cookies to download videos that require login")
                        .font(.body)
                        .multilineTextAlignment(.leading)
                    
                    InfoBox(
                        icon: "lock.shield.fill",
                        title: "Your privacy is protected",
                        message: "• Cookies are only read locally\n• Never sent to any servers\n• Completely optional\n• Can be changed later in Preferences"
                    )
                    
                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Select your browser:")
                                .font(.headline)
                            
                            Picker("", selection: $cookieSource) {
                                Text("Don't use cookies").tag("none")
                                Divider()
                                Text("Safari").tag("safari")
                                Text("Chrome").tag("chrome")
                                Text("Firefox").tag("firefox")
                                Text("Brave").tag("brave")
                                Text("Edge").tag("edge")
                            }
                            .pickerStyle(.radioGroup)
                            .labelsHidden()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if cookieSource != "none" {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Next steps:", systemImage: "info.circle")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text("• Fetcha will request permission to read cookies")
                                .font(.caption)
                            Text("• This is a macOS security feature")
                                .font(.caption)
                            Text("• Click 'Allow' when prompted")
                                .font(.caption)
                        }
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 60)
            }
            .frame(maxHeight: .infinity)
            
            NavigationButtonBar(
                coordinator: coordinator,
                showCancel: false,
                nextTitle: "Continue",
                nextAction: {
                    coordinator.configureCookieSource(cookieSource)
                }
            )
        }
    }
}

// MARK: - Completion

struct CompletionView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var showConfetti = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.green)
                .scaleEffect(showConfetti ? 1.0 : 0.5)
                .animation(.easeOut(duration: 0.3), value: showConfetti)
            
            Text("All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Fetcha is ready to download videos")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(spacing: 10) {
                Label("Paste any video URL to start downloading", systemImage: "link")
                    .font(.caption)
                Label("Use ⌘V to paste from clipboard", systemImage: "command")
                    .font(.caption)
                Label("Check Preferences (⌘,) for more options", systemImage: "gear")
                    .font(.caption)
            }
            .padding(.horizontal, 60)
            
            Spacer()
            
            Button("Start Using Fetcha") {
                coordinator.completeOnboarding()
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 30)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Helper Views

struct NavigationButtonBar: View {
    let coordinator: OnboardingCoordinator
    let showBack: Bool
    let showNext: Bool
    let showCancel: Bool
    let nextTitle: String
    let nextAction: () -> Void
    let nextDisabled: Bool
    
    init(
        coordinator: OnboardingCoordinator,
        showBack: Bool = true,
        showNext: Bool = true,
        showCancel: Bool = true,
        nextTitle: String = "Next",
        nextAction: @escaping () -> Void,
        nextDisabled: Bool = false
    ) {
        self.coordinator = coordinator
        self.showBack = showBack
        self.showNext = showNext
        self.showCancel = showCancel
        self.nextTitle = nextTitle
        self.nextAction = nextAction
        self.nextDisabled = nextDisabled
    }
    
    var body: some View {
        HStack(spacing: 15) {
            if showCancel {
                Button("Cancel") {
                    coordinator.cancel()
                }
                .controlSize(.large)
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            if showBack && coordinator.currentStep.rawValue > 0 {
                Button("Back") {
                    coordinator.goToPreviousStep()
                }
                .controlSize(.large)
                .buttonStyle(.bordered)
            }
            
            if showNext {
                Button(nextTitle) {
                    nextAction()
                }
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(nextDisabled)
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 20)
    }
}

struct OnboardingProgressBar: View {
    let currentStep: OnboardingCoordinator.OnboardingStep
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(NSColor.separatorColor))
                    .frame(height: 4)
                
                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * currentStep.progress, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep.progress)
            }
        }
        .frame(height: 4)
    }
}

struct DependencyRow: View {
    let name: String
    let status: OnboardingCoordinator.DependencyState
    let description: String
    
    var statusIcon: String {
        status.isInstalled ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
    
    var statusColor: Color {
        if status.isInstalled {
            return .green
        } else if status.isRequired {
            return .red
        } else {
            return .orange
        }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundColor(statusColor)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(status.displayName)
                        .fontWeight(.medium)
                    
                    if let version = status.version {
                        Text("v\(version)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if status.isRequired && !status.isInstalled {
                        Text("Required")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }
                
                Text(status.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let path = status.path {
                    Text(path)
                        .font(.caption2)
                        .foregroundColor(Color.secondary.opacity(0.6))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Spacer()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct InfoBox: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .fontWeight(.medium)
                Text(message)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .contentBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}