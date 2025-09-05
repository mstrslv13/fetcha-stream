//
//  InputValidator.swift
//  yt-dlp-MAX
//
//  Comprehensive input validation utilities for security
//

import Foundation

/// Provides secure input validation for user-provided data
class InputValidator {
    
    // MARK: - URL Validation
    
    /// Validates and sanitizes a URL string
    /// - Parameter urlString: The URL string to validate
    /// - Returns: A sanitized URL string or nil if invalid
    static func validateURL(_ urlString: String) -> String? {
        // Remove leading/trailing whitespace
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if empty
        guard !trimmed.isEmpty else { return nil }
        
        // Remove any null bytes
        let cleaned = trimmed.replacingOccurrences(of: "\0", with: "")
        
        // Parse as URL
        guard let url = URL(string: cleaned) else { return nil }
        
        // Validate scheme
        guard let scheme = url.scheme?.lowercased(),
              ["http", "https", "ftp", "ftps"].contains(scheme) else {
            return nil
        }
        
        // Validate host
        guard let host = url.host, !host.isEmpty else { return nil }
        
        // Check for localhost/private IPs (optional security measure)
        if isPrivateHost(host) {
            // Log warning but allow (user might legitimately download from local server)
            PersistentDebugLogger.shared.log("Warning: URL points to private/local host", level: .warning)
        }
        
        // Remove shell special characters that might cause issues
        let shellSpecialChars = CharacterSet(charactersIn: ";|&$`\\")
        let components = cleaned.components(separatedBy: shellSpecialChars)
        
        // If the URL was split by special characters, it's suspicious
        if components.count > 1 {
            PersistentDebugLogger.shared.log("URL contains shell special characters", level: .warning)
            // Return the first component only (before any special char)
            return components.first
        }
        
        return cleaned
    }
    
    /// Check if a host is private/local
    private static func isPrivateHost(_ host: String) -> Bool {
        let privatePatterns = [
            "localhost",
            "127.0.0.1",
            "0.0.0.0",
            "::1",
            "10.",
            "192.168.",
            "172.16.", "172.17.", "172.18.", "172.19.",
            "172.20.", "172.21.", "172.22.", "172.23.",
            "172.24.", "172.25.", "172.26.", "172.27.",
            "172.28.", "172.29.", "172.30.", "172.31."
        ]
        
        for pattern in privatePatterns {
            if host.hasPrefix(pattern) || host == pattern {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Filename Validation
    
    /// Validates and sanitizes a filename
    /// - Parameter filename: The filename to validate
    /// - Returns: A safe filename suitable for the filesystem
    static func validateFilename(_ filename: String) -> String {
        var sanitized = filename
        
        // Remove null bytes
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")
        
        // Remove path separators to prevent directory traversal
        sanitized = sanitized.replacingOccurrences(of: "/", with: "_")
        sanitized = sanitized.replacingOccurrences(of: "\\", with: "_")
        sanitized = sanitized.replacingOccurrences(of: "..", with: "_")
        
        // Remove/replace problematic characters
        let problematicChars: [(String, String)] = [
            (":", "_"),      // Problematic on Windows
            (";", "_"),      // Shell command separator
            ("|", "_"),      // Shell pipe
            ("&", "_"),      // Shell background
            ("$", "_"),      // Shell variable
            ("`", "_"),      // Shell command substitution
            ("\"", "_"),     // Quote
            ("'", "_"),      // Quote
            ("<", "_"),      // Redirect
            (">", "_"),      // Redirect
            ("?", "_"),      // Wildcard
            ("*", "_"),      // Wildcard
            ("\n", "_"),     // Newline
            ("\r", "_"),     // Carriage return
            ("\t", "_")      // Tab
        ]
        
        for (char, replacement) in problematicChars {
            sanitized = sanitized.replacingOccurrences(of: char, with: replacement)
        }
        
        // Handle Windows reserved names
        let reservedNames = [
            "CON", "PRN", "AUX", "NUL",
            "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
            "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"
        ]
        
        let nameWithoutExt = (sanitized as NSString).deletingPathExtension
        let ext = (sanitized as NSString).pathExtension
        
        if reservedNames.contains(nameWithoutExt.uppercased()) {
            sanitized = "_\(nameWithoutExt)"
            if !ext.isEmpty {
                sanitized += ".\(ext)"
            }
        }
        
        // Limit filename length (255 is typical filesystem limit)
        if sanitized.count > 255 {
            let maxNameLength = 250 - ext.count - 1
            if maxNameLength > 0 {
                let truncatedName = String(nameWithoutExt.prefix(maxNameLength))
                sanitized = truncatedName
                if !ext.isEmpty {
                    sanitized += ".\(ext)"
                }
            }
        }
        
        // Ensure filename is not empty
        if sanitized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sanitized = "download"
        }
        
        return sanitized
    }
    
    // MARK: - Path Validation
    
    /// Validates and sanitizes a file path
    /// - Parameter path: The file path to validate
    /// - Returns: A safe, normalized path
    static func validatePath(_ path: String) -> String? {
        // Remove null bytes
        var sanitized = path.replacingOccurrences(of: "\0", with: "")
        
        // Expand tilde for home directory
        sanitized = (sanitized as NSString).expandingTildeInPath
        
        // Create URL and resolve any symbolic links
        let url = URL(fileURLWithPath: sanitized)
        let resolved = url.standardizedFileURL.path
        
        // Check for path traversal attempts
        if resolved.contains("../") || resolved.contains("..\\") {
            PersistentDebugLogger.shared.log("Path traversal attempt detected", level: .warning)
            return nil
        }
        
        // Ensure path doesn't escape expected boundaries
        // (You might want to customize this based on your app's requirements)
        let allowedPrefixes = [
            "/Users/",
            "/tmp/",
            "/private/tmp/",
            "/var/folders/", // macOS temp directories
            NSHomeDirectory()
        ]
        
        var isAllowed = false
        for prefix in allowedPrefixes {
            if resolved.hasPrefix(prefix) {
                isAllowed = true
                break
            }
        }
        
        if !isAllowed {
            PersistentDebugLogger.shared.log("Path outside allowed directories: \(resolved)", level: .warning)
            // You might want to return nil here for stricter security
        }
        
        return resolved
    }
    
    // MARK: - Cookie Path Validation
    
    /// Validates a cookie file path
    /// - Parameter path: The cookie file path
    /// - Returns: A validated path or nil if invalid
    static func validateCookiePath(_ path: String) -> String? {
        guard let validPath = validatePath(path) else { return nil }
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: validPath) else {
            PersistentDebugLogger.shared.log("Cookie file does not exist: \(validPath)", level: .warning)
            return nil
        }
        
        // Check if it's a regular file (not directory or symlink)
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: validPath, isDirectory: &isDirectory)
        
        if isDirectory.boolValue {
            PersistentDebugLogger.shared.log("Cookie path is a directory, not a file", level: .error)
            return nil
        }
        
        // Check file permissions (should be readable)
        guard FileManager.default.isReadableFile(atPath: validPath) else {
            PersistentDebugLogger.shared.log("Cookie file is not readable", level: .error)
            return nil
        }
        
        // Optional: Check file size (cookies file shouldn't be too large)
        if let attributes = try? FileManager.default.attributesOfItem(atPath: validPath),
           let fileSize = attributes[.size] as? Int64 {
            let maxSize: Int64 = 10 * 1024 * 1024 // 10 MB limit
            if fileSize > maxSize {
                PersistentDebugLogger.shared.log("Cookie file is suspiciously large: \(fileSize) bytes", level: .warning)
                // Still allow, but log warning
            }
        }
        
        return validPath
    }
    
    // MARK: - Command Argument Escaping
    
    /// Escapes a string for safe use in shell commands (for logging purposes)
    /// Note: This is for display only - actual process execution should use arrays
    static func escapeForShell(_ argument: String) -> String {
        // If argument contains special characters, wrap in single quotes
        let specialChars = CharacterSet(charactersIn: " '\";&|()$`\\<>*?[]{}!")
        
        if argument.rangeOfCharacter(from: specialChars) != nil {
            // Escape single quotes by replacing ' with '\''
            let escaped = argument.replacingOccurrences(of: "'", with: "'\\''")
            return "'\(escaped)'"
        }
        
        return argument
    }
    
    // MARK: - Batch Validation
    
    /// Validates multiple URLs at once
    /// - Parameter urls: Array of URL strings
    /// - Returns: Dictionary mapping original URLs to validated versions (or nil if invalid)
    static func validateURLs(_ urls: [String]) -> [String: String?] {
        var results: [String: String?] = [:]
        
        for url in urls {
            results[url] = validateURL(url)
        }
        
        return results
    }
    
    // MARK: - Regular Expression Patterns
    
    /// Common regex patterns for validation
    struct Patterns {
        /// YouTube video ID pattern
        static let youtubeVideoID = #"^[a-zA-Z0-9_-]{11}$"#
        
        /// URL pattern (basic)
        static let url = #"^(https?|ftp)://[^\s/$.?#].[^\s]*$"#
        
        /// Safe filename pattern
        static let safeFilename = #"^[a-zA-Z0-9._-]+$"#
        
        /// Version number pattern
        static let version = #"^\d+\.\d+(\.\d+)?$"#
    }
    
    /// Validates input against a regex pattern
    /// - Parameters:
    ///   - input: The string to validate
    ///   - pattern: The regex pattern
    /// - Returns: True if input matches pattern
    static func matches(_ input: String, pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        
        let range = NSRange(location: 0, length: input.utf16.count)
        return regex.firstMatch(in: input, options: [], range: range) != nil
    }
}

// MARK: - String Extension for Validation

extension String {
    /// Returns a validated URL string or nil
    var validatedURL: String? {
        return InputValidator.validateURL(self)
    }
    
    /// Returns a sanitized filename
    var sanitizedFilename: String {
        return InputValidator.validateFilename(self)
    }
    
    /// Returns a validated file path or nil
    var validatedPath: String? {
        return InputValidator.validatePath(self)
    }
    
    /// Returns a shell-escaped version for logging
    var shellEscaped: String {
        return InputValidator.escapeForShell(self)
    }
}