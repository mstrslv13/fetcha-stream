//
//  SelectableDebugConsole.swift
//  yt-dlp-MAX
//
//  Enhanced debug console with text selection and copying capabilities
//

import SwiftUI
import AppKit

/// A selectable, copyable debug console using NSTextView
struct SelectableDebugConsole: NSViewRepresentable {
    @Binding var logs: [PersistentDebugLogger.DebugLog]
    let filter: String
    @State private var shouldAutoScroll = true
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        
        if let textView = scrollView.documentView as? NSTextView {
            textView.isEditable = false
            textView.isSelectable = true
            textView.isRichText = true
            textView.allowsUndo = false
            textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
            textView.backgroundColor = NSColor.textBackgroundColor
            textView.textColor = NSColor.labelColor
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.isAutomaticSpellingCorrectionEnabled = false
            textView.delegate = context.coordinator
            
            // Set up text container for better wrapping
            textView.textContainer?.containerSize = CGSize(width: scrollView.frame.width, height: CGFloat.greatestFiniteMagnitude)
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.lineBreakMode = .byWordWrapping
            
            // Enable automatic text completion for better UX
            textView.isAutomaticTextCompletionEnabled = false
            
            // Set up context menu
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
            menu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Clear Console", action: #selector(Coordinator.clearConsole), keyEquivalent: "k"))
            menu.addItem(NSMenuItem(title: "Export Logs...", action: #selector(Coordinator.exportLogs), keyEquivalent: "e"))
            textView.menu = menu
        }
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // Get filtered logs
        let filteredLogs = getFilteredLogs()
        
        // Build attributed string with colors and formatting
        let attributedString = NSMutableAttributedString()
        
        for log in filteredLogs {
            // Timestamp
            let timestampAttr: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
            let timeString = DateFormatter.localizedString(from: log.timestamp, dateStyle: .none, timeStyle: .medium)
            attributedString.append(NSAttributedString(string: "[\(timeString)] ", attributes: timestampAttr))
            
            // Level indicator with color
            let levelColor: NSColor = {
                switch log.level {
                case .error: return NSColor.systemRed
                case .warning: return NSColor.systemOrange
                case .info: return NSColor.systemBlue
                case .success: return NSColor.systemGreen
                case .command: return NSColor.systemPurple
                }
            }()
            
            let levelAttr: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: levelColor
            ]
            let levelString = String(log.level.rawValue.prefix(1)).uppercased()
            attributedString.append(NSAttributedString(string: "[\(levelString)] ", attributes: levelAttr))
            
            // Message
            let messageAttr: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                .foregroundColor: NSColor.labelColor
            ]
            attributedString.append(NSAttributedString(string: log.message, attributes: messageAttr))
            
            // Details (if any)
            if let details = log.details {
                let detailsAttr: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
                    .foregroundColor: NSColor.tertiaryLabelColor
                ]
                attributedString.append(NSAttributedString(string: "\n    \(details)", attributes: detailsAttr))
            }
            
            attributedString.append(NSAttributedString(string: "\n"))
        }
        
        // Preserve selection if possible
        let currentSelection = textView.selectedRange
        textView.textStorage?.setAttributedString(attributedString)
        
        // Restore selection if it's still valid
        if currentSelection.location + currentSelection.length <= attributedString.length {
            textView.selectedRange = currentSelection
        }
        
        // Auto-scroll to bottom if enabled
        if shouldAutoScroll && !filteredLogs.isEmpty {
            textView.scrollToEndOfDocument(nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func getFilteredLogs() -> [PersistentDebugLogger.DebugLog] {
        switch filter {
        case "yt-dlp":
            return logs.filter { $0.message.contains("yt-dlp") || $0.details?.contains("yt-dlp") ?? false }
        case "ffmpeg":
            return logs.filter { $0.message.contains("ffmpeg") || $0.details?.contains("ffmpeg") ?? false }
        case "App":
            return logs.filter {
                !$0.message.contains("yt-dlp") && !$0.message.contains("ffmpeg") &&
                !(($0.details?.contains("yt-dlp") ?? false) || ($0.details?.contains("ffmpeg") ?? false))
            }
        default:
            return logs
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SelectableDebugConsole
        
        init(_ parent: SelectableDebugConsole) {
            self.parent = parent
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            // Disable auto-scroll when user is selecting text
            if let textView = notification.object as? NSTextView {
                parent.shouldAutoScroll = textView.selectedRange.length == 0
            }
        }
        
        @objc func clearConsole() {
            PersistentDebugLogger.shared.clearLogs()
        }
        
        @objc func exportLogs() {
            // Open the enhanced export view
            let exportView = ExportLogsView()
            let hostingController = NSHostingController(rootView: exportView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Export Logs"
            window.styleMask = [.titled, .closable]
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }
}

/// Enhanced debug console view with toolbar
struct EnhancedDebugConsole: View {
    @StateObject private var debugLogger = PersistentDebugLogger.shared
    @State private var selectedLogType = "All"
    @State private var searchText = ""
    
    let logTypes = ["All", "yt-dlp", "ffmpeg", "App"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 8) {
                // Filter buttons
                ForEach(logTypes, id: \.self) { type in
                    Button(action: { selectedLogType = type }) {
                        Text(type)
                            .font(.system(size: 11))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(selectedLogType == type ? Color.accentColor.opacity(0.2) : Color.clear)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
                    .frame(height: 20)
                
                // Search field - styled to match History panel
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    TextField("Search logs...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                        .frame(width: 180)
                }
                .padding(.vertical, 2)
                
                Spacer()
                
                // Action buttons
                Button(action: copyAllLogs) {
                    Label("Copy All", systemImage: "doc.on.doc")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .help("Copy all visible logs to clipboard")
                
                Button(action: showExportView) {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .help("Export logs with advanced filters")
                
                Button(action: clearLogs) {
                    Label("Clear", systemImage: "trash")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .help("Clear all logs")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Selectable console
            SelectableDebugConsole(
                logs: .constant(filteredLogs),
                filter: selectedLogType
            )
            .background(Color(NSColor.textBackgroundColor))
        }
    }
    
    private var filteredLogs: [PersistentDebugLogger.DebugLog] {
        var logs = debugLogger.logs
        
        // Apply type filter
        switch selectedLogType {
        case "yt-dlp":
            logs = logs.filter { $0.message.contains("yt-dlp") || $0.details?.contains("yt-dlp") ?? false }
        case "ffmpeg":
            logs = logs.filter { $0.message.contains("ffmpeg") || $0.details?.contains("ffmpeg") ?? false }
        case "App":
            logs = logs.filter {
                !$0.message.contains("yt-dlp") && !$0.message.contains("ffmpeg") &&
                !(($0.details?.contains("yt-dlp") ?? false) || ($0.details?.contains("ffmpeg") ?? false))
            }
        default:
            break
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            logs = logs.filter { 
                $0.message.localizedCaseInsensitiveContains(searchText) ||
                ($0.details?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return logs
    }
    
    private func copyAllLogs() {
        let logText = filteredLogs.map { log in
            let timeString = DateFormatter.localizedString(from: log.timestamp, dateStyle: .none, timeStyle: .medium)
            var text = "[\(timeString)] [\(log.level.rawValue)] \(log.message)"
            if let details = log.details {
                text += "\n    \(details)"
            }
            return text
        }.joined(separator: "\n")
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(logText, forType: .string)
    }
    
    private func clearLogs() {
        PersistentDebugLogger.shared.clearLogs()
    }
    
    private func showExportView() {
        let exportView = ExportLogsView()
        let hostingController = NSHostingController(rootView: exportView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Export Logs"
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
}