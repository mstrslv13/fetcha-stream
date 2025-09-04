#!/usr/bin/env swift

import Foundation

// Test script to verify process management

print("Testing Process Management...")

// Test 1: Spawn a long-running process
let sleepProcess = Process()
sleepProcess.executableURL = URL(fileURLWithPath: "/bin/sleep")
sleepProcess.arguments = ["60"] // Sleep for 60 seconds

print("Starting sleep process...")
try! sleepProcess.run()
print("Sleep process PID: \(sleepProcess.processIdentifier)")

// Test 2: Check if process is running
Thread.sleep(forTimeInterval: 1)
print("Is running: \(sleepProcess.isRunning)")

// Test 3: Terminate gracefully
print("Terminating process...")
sleepProcess.terminate()

// Wait a bit
Thread.sleep(forTimeInterval: 1)
print("Is running after terminate: \(sleepProcess.isRunning)")

// Test 4: Test timeout scenario
print("\nTesting timeout scenario...")
let ytdlpProcess = Process()
ytdlpProcess.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/yt-dlp")
ytdlpProcess.arguments = ["--dump-json", "https://invalid-url-that-will-timeout.com"]

let pipe = Pipe()
ytdlpProcess.standardOutput = pipe
ytdlpProcess.standardError = pipe

print("Starting yt-dlp with invalid URL...")
do {
    try ytdlpProcess.run()
    print("yt-dlp process PID: \(ytdlpProcess.processIdentifier)")
    
    // Set up timeout
    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
        if ytdlpProcess.isRunning {
            print("Process still running after 5 seconds, terminating...")
            ytdlpProcess.terminate()
            
            Thread.sleep(forTimeInterval: 1)
            if ytdlpProcess.isRunning {
                print("Process still running, force killing...")
                let killProcess = Process()
                killProcess.executableURL = URL(fileURLWithPath: "/bin/kill")
                killProcess.arguments = ["-9", "\(ytdlpProcess.processIdentifier)"]
                try? killProcess.run()
            }
        }
    }
    
    // Wait for process (with timeout)
    let startTime = Date()
    while ytdlpProcess.isRunning && Date().timeIntervalSince(startTime) < 10 {
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    print("Process finished or timed out")
    print("Final status - Is running: \(ytdlpProcess.isRunning)")
    
} catch {
    print("Error: \(error)")
}

print("\nTest complete!")
print("\nTo verify no zombie processes:")
print("Run: ps aux | grep -E '(yt-dlp|sleep)' | grep -v grep")