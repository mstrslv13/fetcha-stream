//
//  UpdateChecker.swift
//  yt-dlp-MAX
//
//  Checks for app updates from GitHub releases
//

import Foundation
import AppKit

@MainActor
final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()
    
    @Published var updateAvailable = false
    @Published var latestVersion: String?
    @Published var downloadURL: String?
    
    private let githubRepo = AppConstants.githubRepo
    private let currentVersion: String
    
    private init() {
        self.currentVersion = AppConstants.appVersion
    }
    
    func checkForUpdates() async {
        let urlString = "https://api.github.com/repos/\(githubRepo)/releases/latest"
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            
            await MainActor.run {
                processRelease(release)
            }
        } catch {
            PersistentDebugLogger.shared.log("Failed to check for updates: \(error)", level: .error)
        }
    }
    
    private func processRelease(_ release: GitHubRelease) {
        // Remove 'v' prefix if present
        let version = release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName
        
        if isNewerVersion(version, than: currentVersion) {
            latestVersion = version
            updateAvailable = true
            
            // Find DMG download link
            if let dmgAsset = release.assets.first(where: { $0.name.hasSuffix(".dmg") }) {
                downloadURL = dmgAsset.browserDownloadURL
                
                // Send notification
                AppNotificationCenter.shared.notifyUpdateAvailable(
                    version: version,
                    url: dmgAsset.browserDownloadURL
                )
            }
        }
    }
    
    private func isNewerVersion(_ new: String, than current: String) -> Bool {
        let newComponents = new.split(separator: ".").compactMap { Int($0) }
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(newComponents.count, currentComponents.count) {
            let newValue = i < newComponents.count ? newComponents[i] : 0
            let currentValue = i < currentComponents.count ? currentComponents[i] : 0
            
            if newValue > currentValue {
                return true
            } else if newValue < currentValue {
                return false
            }
        }
        
        return false
    }
    
    func openDownloadPage() {
        if let urlString = downloadURL, let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        } else {
            // Fallback to releases page
            if let url = URL(string: "https://github.com/\(githubRepo)/releases") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

// MARK: - GitHub API Models

struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let body: String?
    let assets: [GitHubAsset]
    let publishedAt: String
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case assets
        case publishedAt = "published_at"
    }
}

struct GitHubAsset: Codable {
    let name: String
    let browserDownloadURL: String
    let size: Int
    
    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
        case size
    }
}