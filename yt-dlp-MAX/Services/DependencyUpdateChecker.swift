//
//  DependencyUpdateChecker.swift
//  yt-dlp-MAX
//
//  Checks for updates to yt-dlp and ffmpeg via Homebrew
//

import Foundation
import AppKit

@MainActor
final class DependencyUpdateChecker: ObservableObject {
    static let shared = DependencyUpdateChecker()

    @Published var ytdlpUpdateAvailable = false
    @Published var ffmpegUpdateAvailable = false
    @Published var ytdlpCurrentVersion: String?
    @Published var ytdlpLatestVersion: String?
    @Published var ffmpegCurrentVersion: String?
    @Published var ffmpegLatestVersion: String?
    @Published var isChecking = false

    private init() {}

    /// Check for updates to both yt-dlp and ffmpeg using Homebrew
    func checkForUpdates() async {
        isChecking = true
        defer { isChecking = false }

        PersistentDebugLogger.shared.log("Checking for dependency updates via Homebrew...", level: .info)

        // First, update brew itself to get latest package info
        await updateBrewDatabase()

        // Check yt-dlp
        await checkYtdlpUpdate()

        // Check ffmpeg
        await checkFfmpegUpdate()

        // Log results
        if ytdlpUpdateAvailable {
            PersistentDebugLogger.shared.log(
                "yt-dlp update available: \(ytdlpCurrentVersion ?? "unknown") → \(ytdlpLatestVersion ?? "unknown")",
                level: .info
            )

            // Send notification
            AppNotificationCenter.shared.addNotification(
                type: .update,
                title: "yt-dlp Update Available",
                message: "Version \(ytdlpLatestVersion ?? "unknown") is available. Click to upgrade."
            )
        }

        if ffmpegUpdateAvailable {
            PersistentDebugLogger.shared.log(
                "ffmpeg update available: \(ffmpegCurrentVersion ?? "unknown") → \(ffmpegLatestVersion ?? "unknown")",
                level: .info
            )

            // Send notification
            AppNotificationCenter.shared.addNotification(
                type: .update,
                title: "ffmpeg Update Available",
                message: "Version \(ffmpegLatestVersion ?? "unknown") is available. Click to upgrade."
            )
        }

        if !ytdlpUpdateAvailable && !ffmpegUpdateAvailable {
            PersistentDebugLogger.shared.log("All dependencies are up to date", level: .success)
        }
    }

    /// Update Homebrew's package database
    private func updateBrewDatabase() async {
        PersistentDebugLogger.shared.log("Updating Homebrew database...", level: .info)

        let result = await runBrewCommand(["update"])
        if result.exitCode == 0 {
            PersistentDebugLogger.shared.log("Homebrew database updated", level: .success)
        } else {
            PersistentDebugLogger.shared.log(
                "Failed to update Homebrew database: \(result.error)",
                level: .warning
            )
        }
    }

    /// Check for yt-dlp updates
    private func checkYtdlpUpdate() async {
        // Get current version
        let currentResult = await runCommand("/opt/homebrew/bin/yt-dlp", args: ["--version"])
        if currentResult.exitCode == 0 {
            ytdlpCurrentVersion = currentResult.output.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            // Try alternative path
            let altResult = await runCommand("/usr/local/bin/yt-dlp", args: ["--version"])
            if altResult.exitCode == 0 {
                ytdlpCurrentVersion = altResult.output.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                PersistentDebugLogger.shared.log("yt-dlp not found or not installed via Homebrew", level: .warning)
                return
            }
        }

        // Check if update available
        let outdatedResult = await runBrewCommand(["outdated", "yt-dlp", "--json"])
        if outdatedResult.exitCode == 0 && !outdatedResult.output.isEmpty {
            // Parse JSON to get latest version
            if let data = outdatedResult.output.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let ytdlpInfo = json.first,
               let latestVersion = ytdlpInfo["current_version"] as? String {
                ytdlpLatestVersion = latestVersion
                ytdlpUpdateAvailable = true
            }
        }
    }

    /// Check for ffmpeg updates
    private func checkFfmpegUpdate() async {
        // Get current version
        let currentResult = await runCommand("/opt/homebrew/bin/ffmpeg", args: ["-version"])
        if currentResult.exitCode == 0 {
            ffmpegCurrentVersion = extractFfmpegVersion(from: currentResult.output)
        } else {
            // Try alternative path
            let altResult = await runCommand("/usr/local/bin/ffmpeg", args: ["-version"])
            if altResult.exitCode == 0 {
                ffmpegCurrentVersion = extractFfmpegVersion(from: altResult.output)
            } else {
                PersistentDebugLogger.shared.log("ffmpeg not found or not installed via Homebrew", level: .warning)
                return
            }
        }

        // Check if update available
        let outdatedResult = await runBrewCommand(["outdated", "ffmpeg", "--json"])
        if outdatedResult.exitCode == 0 && !outdatedResult.output.isEmpty {
            // Parse JSON to get latest version
            if let data = outdatedResult.output.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let ffmpegInfo = json.first,
               let latestVersion = ffmpegInfo["current_version"] as? String {
                ffmpegLatestVersion = latestVersion
                ffmpegUpdateAvailable = true
            }
        }
    }

    /// Extract version number from ffmpeg output
    private func extractFfmpegVersion(from output: String) -> String? {
        // ffmpeg version format: "ffmpeg version 6.0 Copyright..."
        let lines = output.components(separatedBy: .newlines)
        guard let firstLine = lines.first else { return nil }

        let components = firstLine.components(separatedBy: " ")
        if components.count >= 3, components[0] == "ffmpeg", components[1] == "version" {
            return components[2]
        }
        return nil
    }

    /// Upgrade yt-dlp via Homebrew
    func upgradeYtdlp() async -> Bool {
        PersistentDebugLogger.shared.log("Upgrading yt-dlp via Homebrew...", level: .info)

        let result = await runBrewCommand(["upgrade", "yt-dlp"])
        if result.exitCode == 0 {
            PersistentDebugLogger.shared.log("yt-dlp upgraded successfully", level: .success)

            // Refresh current version
            ytdlpUpdateAvailable = false
            await checkYtdlpUpdate()

            return true
        } else {
            PersistentDebugLogger.shared.log(
                "Failed to upgrade yt-dlp: \(result.error)",
                level: .error
            )
            return false
        }
    }

    /// Upgrade ffmpeg via Homebrew
    func upgradeFfmpeg() async -> Bool {
        PersistentDebugLogger.shared.log("Upgrading ffmpeg via Homebrew...", level: .info)

        let result = await runBrewCommand(["upgrade", "ffmpeg"])
        if result.exitCode == 0 {
            PersistentDebugLogger.shared.log("ffmpeg upgraded successfully", level: .success)

            // Refresh current version
            ffmpegUpdateAvailable = false
            await checkFfmpegUpdate()

            return true
        } else {
            PersistentDebugLogger.shared.log(
                "Failed to upgrade ffmpeg: \(result.error)",
                level: .error
            )
            return false
        }
    }

    /// Run a brew command
    private func runBrewCommand(_ args: [String]) async -> (output: String, error: String, exitCode: Int32) {
        // Try Apple Silicon path first
        var result = await runCommand("/opt/homebrew/bin/brew", args: args)
        if result.exitCode == 0 {
            return result
        }

        // Try Intel path
        result = await runCommand("/usr/local/bin/brew", args: args)
        if result.exitCode == 0 {
            return result
        }

        // Try PATH
        return await runCommand("brew", args: args)
    }

    /// Run a command and return output
    private func runCommand(_ path: String, args: [String]) async -> (output: String, error: String, exitCode: Int32) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        var output = ""
        var errorOutput = ""
        var exitCode: Int32 = -1

        do {
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            output = String(data: outputData, encoding: .utf8) ?? ""
            errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            exitCode = process.terminationStatus
        } catch let executionError {
            errorOutput = executionError.localizedDescription
        }

        return (output, errorOutput, exitCode)
    }
}
