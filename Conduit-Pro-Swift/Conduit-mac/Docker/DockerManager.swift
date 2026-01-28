//
//  DockerManager.swift
//  Conduit-mac
//
//  Created by Ali Ghanavati on 2026-01-27.
//

import Foundation
import Combine
import AppKit
import UniformTypeIdentifiers

class DockerManager: ObservableObject {
    
    @Published var isDockerInstalled: Bool = false
    @Published var isDockerRunning: Bool = false
    
    @Published var isRunning: Bool = false
    @Published var containerStatus: String = "Checking..."
    @Published var nodeID: String = "Not Available"
    @Published var healthStatus: String = "Unknown"
    
    @Published var isUpdating: Bool = false
    
    @Published var cpuUsage: String = "0%"
    @Published var memUsage: String = "0%"
    @Published var onlineUsers: String = "0"
    @Published var connectingUsers: String = "0"
    @Published var uploadTraffic: String = "0B"
    @Published var downloadTraffic: String = "0B"
    @Published var uptime: String = "0s"
    
    @Published var peakUsers: String = "0"
    @Published var uploadSpeed: String = "0 B/s"
    @Published var downloadSpeed: String = "0 B/s"
    
    @Published var logs: String = ""
    
    private var timer: Timer?
    private let containerName = "conduit-mac"
    private let conduitImage = "ghcr.io/ssmirr/conduit/conduit:latest"
    private let alpineImage = "alpine:latest"
    private let volumeName = "conduit-data"
    
    private var lastUploadBytes: Double = 0
    private var lastDownloadBytes: Double = 0
    private var isFirstSpeedCheck = true
    
    private var lastRxBytes: Double = 0
    private var lastTxBytes: Double = 0
    private var lastCheckTime: TimeInterval = 0
    
    
    init() {
        checkPrerequisites()
        startMonitoring()
    }
    
    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.refreshLoop()
        }
    }
    
    private func refreshLoop() {
        if isUpdating { return }
        
        DispatchQueue.global(qos: .background).async {
            self.checkPrerequisites()
            
            if self.isDockerRunning {
                self.checkStatus()
                
                if self.isRunning {
                    self.fetchStats()
                    self.fetchLogs()
                    self.fetchRealTimeSpeed()
                    
                    if self.nodeID == "Not Available" || self.nodeID.isEmpty {
                        self.fetchNodeID()
                    }
                }
            }
        }
    }
    
    func updateNode(maxClients: String, bandwidth: String) {
        if !isDockerRunning { return }
        
        DispatchQueue.main.async {
            self.isUpdating = true
            self.containerStatus = "Updating..."
            self.logs += "\n[UPDATE] Checking for new version..."
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let pullOutput = self.runCommand(cmd: "docker", args: ["pull", self.conduitImage])
            
            DispatchQueue.main.async {
                self.logs += "\n[UPDATE] \(pullOutput)"
            }
            
            if self.isRunning {
                _ = self.runCommand(cmd: "docker", args: ["stop", self.containerName])
                _ = self.runCommand(cmd: "docker", args: ["rm", "-f", self.containerName])
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.startContainer(maxClients: maxClients, bandwidth: bandwidth)
                
                DispatchQueue.main.async {
                    self.isUpdating = false
                    self.logs += "\n[UPDATE] Update process finished."
                }
            }
        }
    }
    
    
    func checkPrerequisites() {
        let appExists = FileManager.default.fileExists(atPath: "/Applications/Docker.app")
        let pathCheck = runCommand(cmd: "which", args: ["docker"])
        let cliExists = !pathCheck.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        var running = false
        if cliExists {
            let infoCheck = runCommand(cmd: "docker", args: ["info"])
            running = !infoCheck.contains("Cannot connect") && !infoCheck.contains("Is the docker daemon running") && !infoCheck.contains("no such file")
        }
        
        DispatchQueue.main.async {
            self.isDockerInstalled = appExists || cliExists
            self.isDockerRunning = running
            
            if !self.isDockerInstalled {
                self.containerStatus = "Docker Missing"
                self.healthStatus = "Install Required"
            } else if !running {
                self.containerStatus = "Docker Stopped"
                self.healthStatus = "Start Required"
            }
        }
    }
    
    func openDockerApp() {
        let url = URL(fileURLWithPath: "/Applications/Docker.app")
        NSWorkspace.shared.open(url)
    }
    
    func downloadDocker() {
        if let url = URL(string: "https://www.docker.com/products/docker-desktop/") {
            NSWorkspace.shared.open(url)
        }
    }
    
    
    func toggleService(maxClients: String, bandwidth: String) {
        if isRunning {
            stopContainer()
        } else {
            startContainer(maxClients: maxClients, bandwidth: bandwidth)
        }
    }
    
    func stopContainer() {
        DispatchQueue.main.async {
            self.containerStatus = "Stopping..."
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.runCommand(cmd: "docker", args: ["stop", self.containerName])
            
            DispatchQueue.main.async {
                self.isRunning = false
                self.containerStatus = "Stopped"
                self.healthStatus = "Offline"
                self.cpuUsage = "0%"
                self.onlineUsers = "0"
                self.connectingUsers = "0"
                self.uploadSpeed = "0 B/s"
                self.downloadSpeed = "0 B/s"
            }
        }
    }
    
    func startContainer(maxClients: String, bandwidth: String) {
        if !isDockerRunning { return }
        
        DispatchQueue.main.async {
            self.containerStatus = "Starting..."
            self.logs += "\n[SYSTEM] Initializing..."
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.ensureImageExists(name: self.conduitImage) {
                DispatchQueue.main.async { self.logs += "\n[ERROR] Image check failed." }
                return
            }
            
            _ = self.ensureImageExists(name: self.alpineImage)
            _ = self.runCommand(cmd: "docker", args: [
                "run", "--rm",
                "-v", "\(self.volumeName):/home/conduit/data",
                self.alpineImage,
                "chown", "-R", "1000:1000", "/home/conduit/data"
            ])
            
            _ = self.runCommand(cmd: "docker", args: ["rm", "-f", self.containerName])
            
            let bwLimit = (bandwidth == "-1" || bandwidth.isEmpty) ? "-1" : bandwidth
            let clientsLimit = maxClients.isEmpty ? "200" : maxClients
            
            let args = [
                "run", "-d",
                "--name", self.containerName,
                "--restart", "unless-stopped",
                "-v", "\(self.volumeName):/home/conduit/data",
                "--network", "bridge",
                "-p", "443:443/tcp",
                self.conduitImage,
                "start", "--max-clients", clientsLimit, "--bandwidth", bwLimit, "-v"
            ]
            
            let runOutput = self.runCommand(cmd: "docker", args: args)
            
            DispatchQueue.main.async {
                if runOutput.lowercased().contains("error") && !runOutput.contains("WARNING") {
                    self.logs += "\n[ERROR] Start failed: \(runOutput)"
                    self.containerStatus = "Failed"
                } else {
                    self.logs += "\n[SYSTEM] Container started. ID: \(runOutput.prefix(12))"
                    self.isRunning = true
                    self.containerStatus = "Running"
                    self.healthStatus = "Healthy"
                    self.lastCheckTime = 0
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                        self.fetchNodeID()
                    }
                }
            }
        }
    }
    
    func uninstall() {
        stopContainer()
        DispatchQueue.global(qos: .background).async {
            _ = self.runCommand(cmd: "docker", args: ["rm", "-f", self.containerName])
            _ = self.runCommand(cmd: "docker", args: ["volume", "rm", self.volumeName])
            _ = self.runCommand(cmd: "docker", args: ["rmi", self.conduitImage])
            
            DispatchQueue.main.async {
                self.containerStatus = "Uninstalled"
                self.nodeID = "Deleted"
                self.logs += "\n[SYSTEM] Uninstall complete."
                self.isRunning = false
            }
        }
    }
    
    
    func fetchNodeID() {
        let cmd = "cat /home/conduit/data/conduit_key.json | grep 'privateKeyBase64' | awk -F'\"' '{print $4}' | base64 -d 2>/dev/null | tail -c 32 | base64 | tr -d '=\\n'"
        let output = self.runCommand(cmd: "docker", args: ["exec", self.containerName, "sh", "-c", cmd])
        let lines = output.components(separatedBy: .newlines)
        if let lastLine = lines.last(where: { !$0.isEmpty && !$0.contains("invalid") && !$0.contains("Error") }) {
            let cleanedID = lastLine.trimmingCharacters(in: .whitespacesAndNewlines)
            DispatchQueue.main.async { if !cleanedID.isEmpty { self.nodeID = cleanedID } }
        }
    }
    
    func backupKey() {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.ensureImageExists(name: self.alpineImage)
            let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? "/tmp"
            let filename = "conduit_key_backup_\(Int(Date().timeIntervalSince1970)).json"
            
            let res = self.runCommand(cmd: "docker", args: [
                "run", "--rm", "-v", "\(self.volumeName):/data", "-v", "\(downloadsPath):/backup",
                self.alpineImage, "cp", "/data/conduit_key.json", "/backup/\(filename)"
            ])
            DispatchQueue.main.async { self.logs += res.isEmpty ? "\n[BACKUP] Saved to Downloads" : "\n[BACKUP] \(res)" }
        }
    }
    
    func restoreKey() {
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.allowedContentTypes = [.json]
            panel.prompt = "Restore Backup"
            panel.message = "Select your backup file"
            
            if panel.runModal() == .OK, let url = panel.url {
                self.performRestoreOperation(fileURL: url)
            }
        }
    }
    
    private func performRestoreOperation(fileURL: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.ensureImageExists(name: self.alpineImage)
            
            let folderPath = fileURL.deletingLastPathComponent().path
            let fileName = fileURL.lastPathComponent
            
            DispatchQueue.main.async { self.logs += "\n[RESTORE] Restoring from: \(fileName)..." }
            
            _ = self.runCommand(cmd: "docker", args: ["stop", self.containerName])
            _ = self.runCommand(cmd: "docker", args: ["volume", "create", self.volumeName])
            
            let res = self.runCommand(cmd: "docker", args: [
                "run", "--rm",
                "-v", "\(self.volumeName):/data",
                "-v", "\(folderPath):/backup",
                self.alpineImage,
                "sh", "-c", "cp '/backup/\(fileName)' /data/conduit_key.json && chown 1000:1000 /data/conduit_key.json"
            ])
            
            DispatchQueue.main.async {
                if res.isEmpty {
                    self.logs += "\n[RESTORE] Success! Please Start Service."
                    self.isRunning = false; self.containerStatus = "Stopped"
                } else {
                    self.logs += "\n[ERROR] Restore Failed: \(res)"
                }
            }
        }
    }
    
    func getRawPrivateKey(completion: @escaping (String?) -> Void) {
        let cmd = "grep 'privateKeyBase64' /home/conduit/data/conduit_key.json | awk -F'\"' '{print $4}'"
        
        DispatchQueue.global(qos: .userInitiated).async {
            let output = self.runCommand(cmd: "docker", args: ["exec", self.containerName, "sh", "-c", cmd])
            let cleanKey = output.trimmingCharacters(in: .whitespacesAndNewlines)
            
            DispatchQueue.main.async {
                if !cleanKey.isEmpty && !cleanKey.contains("Error") {
                    completion(cleanKey)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    
    private func ensureImageExists(name: String) -> Bool {
        let check = runCommand(cmd: "docker", args: ["image", "inspect", name])
        if check.contains("\"Id\":") { return true }
        
        DispatchQueue.main.async { self.logs += "\n[SYSTEM] Downloading \(name)..." }
        _ = runCommand(cmd: "docker", args: ["pull", name])
        
        let reCheck = runCommand(cmd: "docker", args: ["image", "inspect", name])
        return reCheck.contains("\"Id\":")
    }
    
    private func checkStatus() {
        let output = self.runCommand(cmd: "docker", args: ["ps", "-a", "--format", "{{.State}}|{{.Status}}", "-f", "name=\(self.containerName)"])
        let parts = output.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "|")
        
        DispatchQueue.main.async {
            if parts.count >= 2 {
                let state = parts[0].lowercased()
                let statusRaw = parts[1]
                let cleanUptime = statusRaw.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespaces) ?? statusRaw
                
                if state == "running" || state == "restarting" {
                    self.isRunning = true
                    self.containerStatus = "Running"
                    self.healthStatus = "Healthy"
                    self.uptime = cleanUptime.replacingOccurrences(of: "Up ", with: "")
                } else {
                    self.isRunning = false
                    self.uptime = "Offline"
                    if !self.containerStatus.contains("Starting") && !self.containerStatus.contains("Stopping") && !self.containerStatus.contains("Updating") {
                        self.containerStatus = "Stopped"
                        self.healthStatus = "Offline"
                    }
                }
            } else {
                self.isRunning = false
                self.uptime = "Offline"
                if !self.containerStatus.contains("Starting") && !self.containerStatus.contains("Updating") {
                    self.containerStatus = "Stopped"
                }
            }
        }
    }
    
    private func fetchStats() {
        let output = self.runCommand(cmd: "docker", args: ["stats", "--no-stream", "--format", "{{.CPUPerc}}|{{.MemUsage}}", self.containerName])
        let components = output.components(separatedBy: "|")
        if components.count >= 2 {
            DispatchQueue.main.async {
                self.cpuUsage = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                self.memUsage = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }
    
    private func fetchLogs() {
        let output = self.runCommand(cmd: "docker", args: ["logs", "--tail", "100", self.containerName])
        DispatchQueue.main.async { if !output.isEmpty { self.logs = output } }
        
        if let lastStats = output.components(separatedBy: "\n").filter({ $0.contains("[STATS]") }).last {
            parseLogStats(line: lastStats)
        }
    }
    
    private func parseLogStats(line: String) {
        let parts = line.components(separatedBy: "|")
        var currentConn = "0"
        
        for part in parts {
            let cleanPart = part.trimmingCharacters(in: .whitespaces)
            if cleanPart.contains("Connected:") {
                let value = cleanPart.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "0"
                currentConn = value
                DispatchQueue.main.async { self.onlineUsers = value }
            } else if cleanPart.contains("Connecting:") {
                let value = cleanPart.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "0"
                DispatchQueue.main.async { self.connectingUsers = value }
            } else if cleanPart.contains("Up:") && !cleanPart.contains("Uptime") {
                let value = cleanPart.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "0B"
                DispatchQueue.main.async { self.uploadTraffic = value }
            } else if cleanPart.contains("Down:") {
                let value = cleanPart.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "0B"
                DispatchQueue.main.async { self.downloadTraffic = value }
            }
        }
        
        if let usersInt = Int(currentConn), let peakInt = Int(self.peakUsers) {
            if usersInt > peakInt {
                DispatchQueue.main.async { self.peakUsers = String(usersInt) }
            }
        }
    }
    
    private func fetchRealTimeSpeed() {
        let now = Date().timeIntervalSince1970
        let output = self.runCommand(cmd: "docker", args: ["exec", self.containerName, "cat", "/proc/net/dev"])
        
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("eth0:") {
                let dataPart = trimmed.replacingOccurrences(of: "eth0:", with: "")
                let stats = dataPart.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                
                if stats.count >= 9, let currentRx = Double(stats[0]), let currentTx = Double(stats[8]) {
                    if lastCheckTime > 0 {
                        let timeDiff = now - lastCheckTime
                        if timeDiff > 0 {
                            let downSpeedVal = (currentRx - lastRxBytes) / timeDiff
                            let upSpeedVal = (currentTx - lastTxBytes) / timeDiff
                            
                            if currentRx >= lastRxBytes {
                                DispatchQueue.main.async {
                                    self.downloadSpeed = self.formatSpeed(downSpeedVal)
                                    self.uploadSpeed = self.formatSpeed(upSpeedVal)
                                }
                            }
                        }
                    }
                    lastRxBytes = currentRx
                    lastTxBytes = currentTx
                    lastCheckTime = now
                }
            }
        }
    }
    
    private func parseBytes(_ string: String) -> Double {
        let parts = string.components(separatedBy: " ")
        guard let value = Double(parts.first ?? "0") else { return 0 }
        let unit = parts.last?.uppercased() ?? "B"
        switch unit {
        case "TB": return value * 1024 * 1024 * 1024 * 1024
        case "GB": return value * 1024 * 1024 * 1024
        case "MB": return value * 1024 * 1024
        case "KB": return value * 1024
        default: return value
        }
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond >= 1024 * 1024 * 1024 {
            return String(format: "%.2f GB/s", bytesPerSecond / (1024 * 1024 * 1024))
        } else if bytesPerSecond >= 1024 * 1024 {
            return String(format: "%.2f MB/s", bytesPerSecond / (1024 * 1024))
        } else if bytesPerSecond >= 1024 {
            return String(format: "%.2f KB/s", bytesPerSecond / 1024)
        } else {
            return String(format: "%.0f B/s", bytesPerSecond)
        }
    }
    
    private func runCommand(cmd: String, args: [String]) -> String {
        let task = Process()
        let pipe = Pipe()
        
        var env = ProcessInfo.processInfo.environment
        let existingPath = env["PATH"] ?? ""
        let newPath = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin" + (existingPath.isEmpty ? "" : ":" + existingPath)
        env["PATH"] = newPath
        task.environment = env
        
        let dockerPath = ["/usr/local/bin/docker", "/opt/homebrew/bin/docker", "/usr/bin/docker"].first(where: { FileManager.default.fileExists(atPath: $0) }) ?? "docker"
        
        if cmd == "docker" {
            task.executableURL = URL(fileURLWithPath: dockerPath)
            task.arguments = args
        } else {
            task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            var allArgs = args; allArgs.insert(cmd, at: 0); task.arguments = allArgs
        }
        
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
}
