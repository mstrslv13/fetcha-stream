import SwiftUI
import AppKit

struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var category: BugCategory = .downloadFailed
    @State private var description = ""
    @State private var email = ""
    @State private var includeSystemInfo = true
    @State private var includeLogs = true
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    enum BugCategory: String, CaseIterable {
        case downloadFailed = "Download Failed"
        case appCrash = "App Crashed"
        case uiIssue = "Interface Problem"
        case installationIssue = "Installation Problem"
        case cookieIssue = "Cookie/Authentication Issue"
        case performanceIssue = "Performance Problem"
        case featureRequest = "Feature Request"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .downloadFailed: return "arrow.down.circle.fill"
            case .appCrash: return "exclamationmark.triangle.fill"
            case .uiIssue: return "macwindow.on.rectangle"
            case .installationIssue: return "wrench.and.screwdriver.fill"
            case .cookieIssue: return "lock.shield.fill"
            case .performanceIssue: return "speedometer"
            case .featureRequest: return "lightbulb.fill"
            case .other: return "questionmark.circle.fill"
            }
        }
        
        var description: String {
            switch self {
            case .downloadFailed: return "Video download failed or incomplete"
            case .appCrash: return "Application crashed or froze"
            case .uiIssue: return "User interface problems or glitches"
            case .installationIssue: return "Problems with dependency installation"
            case .cookieIssue: return "Cookie extraction or authentication issues"
            case .performanceIssue: return "Slow performance or high resource usage"
            case .featureRequest: return "Suggest a new feature or improvement"
            case .other: return "Something else"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "ladybug.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    
                    Text("Report an Issue")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                Text("Help us improve Fetcha by reporting bugs and issues")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category selection
                    VStack(alignment: .leading, spacing: 10) {
                        Label("What type of issue are you experiencing?", systemImage: "tag.fill")
                            .font(.headline)
                        
                        Picker("Category", selection: $category) {
                            ForEach(BugCategory.allCases, id: \.self) { cat in
                                Label(cat.rawValue, systemImage: cat.icon)
                                    .tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 250)
                        
                        Text(category.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Describe what happened", systemImage: "text.alignleft")
                            .font(.headline)
                        
                        TextEditor(text: $description)
                            .font(.body)
                            .frame(height: 150)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                            .background(
                                Group {
                                    if description.isEmpty {
                                        Text("Please provide as much detail as possible:\n• What were you trying to do?\n• What happened instead?\n• Can you reproduce the issue?")
                                            .foregroundColor(.secondary)
                                            .padding(8)
                                            .allowsHitTesting(false)
                                    }
                                }
                                , alignment: .topLeading
                            )
                    }
                    
                    // Email (optional)
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Email (optional)", systemImage: "envelope.fill")
                            .font(.headline)
                        
                        TextField("your@email.com", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 300)
                        
                        Text("We'll only use this to follow up on your report")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Data inclusion options
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Include diagnostic data", systemImage: "doc.text.fill")
                            .font(.headline)
                        
                        Toggle("Include system information", isOn: $includeSystemInfo)
                            .help("macOS version, hardware info, app version")
                        
                        Toggle("Include recent logs", isOn: $includeLogs)
                            .help("Last 100 log entries (no personal data)")
                        
                        Text("This helps us diagnose the issue faster")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Diagnostic info preview
                    if includeSystemInfo || includeLogs {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Data to be included:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                ScrollView {
                                    Text(generateDiagnosticPreview())
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .scrollContentBackground(.hidden)
                                .background(FreshUI.Colors.background)
                                .frame(height: 80)
                            }
                        }
                    }
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background(FreshUI.Colors.background)

            // Footer buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Open GitHub Issues") {
                    openGitHubIssues()
                }
                
                Button("Submit Report") {
                    submitReport()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(description.isEmpty || isSubmitting)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .alert("Report Submitted", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you for your feedback! Your report has been submitted successfully.")
        }
        .alert("Submission Failed", isPresented: $showingError) {
            Button("OK") { }
            Button("Copy Report") {
                copyReportToClipboard()
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func generateDiagnosticPreview() -> String {
        var info = ""
        
        if includeSystemInfo {
            info += "=== System Information ===\n"
            info += "App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")\n"
            info += "macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)\n"
            info += "Architecture: \(getArchitecture())\n"
            
            // Check dependencies
            Task {
                let deps = await OnboardingCoordinator.shared.checkDependencies()
                info += "yt-dlp: \(deps.ytdlp.isInstalled ? "✓ \(deps.ytdlp.version ?? "")" : "✗")\n"
                info += "ffmpeg: \(deps.ffmpeg.isInstalled ? "✓ \(deps.ffmpeg.version ?? "")" : "✗")\n"
                info += "Homebrew: \(deps.homebrew.isInstalled ? "✓ \(deps.homebrew.version ?? "")" : "✗")\n"
            }
        }
        
        if includeLogs {
            info += "\n=== Recent Logs ===\n"
            let recentLogs = PersistentDebugLogger.shared.getRecentLogs(count: 10)
            info += recentLogs.joined(separator: "\n")
        }
        
        return info
    }
    
    private func getArchitecture() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let machine = withUnsafePointer(to: &sysinfo.machine) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) { machine in
                String(cString: machine)
            }
        }
        return machine
    }
    
    private func generateFullReport() async -> String {
        var report = """
        # Bug Report - Fetcha
        
        ## Category
        \(category.rawValue)
        
        ## Description
        \(description)
        
        """
        
        if !email.isEmpty {
            report += "## Contact\n\(email)\n\n"
        }
        
        if includeSystemInfo {
            report += """
            ## System Information
            - App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
            - Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
            - macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
            - Architecture: \(getArchitecture())
            
            """
            
            // Add dependency status
            let deps = await OnboardingCoordinator.shared.checkDependencies()
            report += """
            ## Dependencies
            - yt-dlp: \(deps.ytdlp.isInstalled ? "✓ Installed (v\(deps.ytdlp.version ?? "unknown"))" : "✗ Not installed")
            - ffmpeg: \(deps.ffmpeg.isInstalled ? "✓ Installed (v\(deps.ffmpeg.version ?? "unknown"))" : "✗ Not installed")
            - Homebrew: \(deps.homebrew.isInstalled ? "✓ Installed (v\(deps.homebrew.version ?? "unknown"))" : "✗ Not installed")
            
            """
        }
        
        if includeLogs {
            report += """
            ## Recent Logs
            ```
            \(PersistentDebugLogger.shared.getRecentLogs(count: 50).joined(separator: "\n"))
            ```
            
            """
        }
        
        report += """
        ---
        Generated: \(Date().formatted())
        """
        
        return report
    }
    
    private func submitReport() {
        isSubmitting = true
        
        Task {
            let report = await generateFullReport()
            
            // Create GitHub issue URL with pre-filled content
            let title = "[\(category.rawValue)] Issue Report"
            let body = report
            
            // URL encode the parameters
            guard let titleEncoded = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                errorMessage = "Failed to encode report data"
                showingError = true
                isSubmitting = false
                return
            }
            
            let githubURL = "https://github.com/mstrslv13/fetcha-stream/issues/new?title=\(titleEncoded)&body=\(bodyEncoded)"
            
            // Try to open GitHub
            if let url = URL(string: githubURL) {
                NSWorkspace.shared.open(url)
                showingSuccess = true
            } else {
                // Fallback: copy to clipboard
                copyReportToClipboard()
                errorMessage = "Could not open GitHub. Report copied to clipboard."
                showingError = true
            }
            
            isSubmitting = false
        }
    }
    
    private func copyReportToClipboard() {
        Task {
            let report = await generateFullReport()
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(report, forType: .string)
        }
    }
    
    private func openGitHubIssues() {
        if let url = URL(string: "https://github.com/mstrslv13/fetcha-stream/issues") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Preview

struct BugReportView_Previews: PreviewProvider {
    static var previews: some View {
        BugReportView()
            .frame(width: 600, height: 500)
    }
}