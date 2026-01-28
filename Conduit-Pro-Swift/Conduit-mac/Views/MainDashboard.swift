//
//  MainDashboard.swift
//  Conduit-mac
//
//  Created by Ali Ghanavati on 2026-01-28.
//

import SwiftUI

struct MainDashboard: View {
    @ObservedObject var manager: DockerManager
    @Binding var maxClients: String
    @Binding var bandwidth: String
    @Binding var showUninstallAlert: Bool
    @Binding var showHelpSheet: Bool
    
    @State private var logsHeight: CGFloat = 200
    @State private var isLogsExpanded: Bool = true
    @State private var dragStartHeight: CGFloat = 0
    
    @State private var showStartSuccessAlert = false
    @State private var hasShownStartAlert = false
    
    var body: some View {
        HStack(spacing: 0) {
            // SIDEBAR
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Label("Conduit Pro", systemImage: "network.badge.shield.half.filled")
                        .font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Text(appVersion).font(.caption2).foregroundColor(.gray)
                }
                .padding(.horizontal, 5)
                Divider().background(Color.gray.opacity(0.3))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CONFIGURATION").font(.caption).fontWeight(.bold).foregroundColor(.gray)
                            Group {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Max Clients").font(.caption).foregroundColor(.secondary)
                                    TextField("200", text: $maxClients).textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Bandwidth (Mbps)").font(.caption).foregroundColor(.secondary)
                                    TextField("5 or -1 for unlimited", text: $bandwidth).textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                            .disabled(manager.isRunning || manager.containerStatus.contains("..."))
                            .opacity(manager.isRunning ? 0.6 : 1)
                            
                            Button(action: {
                                if manager.isRunning { hasShownStartAlert = false }
                                manager.toggleService(maxClients: maxClients, bandwidth: bandwidth)
                            }) {
                                HStack {
                                    if manager.containerStatus.contains("...") { ProgressView().controlSize(.small) }
                                    else { Image(systemName: manager.isRunning ? "stop.fill" : "play.fill") }
                                    Text(manager.isRunning ? "Stop Service" : "Start Service").fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(manager.isRunning ? .red : .green)
                            .disabled(manager.containerStatus.contains("..."))
                        }
                        Divider().background(Color.gray.opacity(0.3))
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TOOLS").font(.caption).fontWeight(.bold).foregroundColor(.gray)
                            HStack {
                                ToolButton(icon: "arrow.down.doc", title: "Backup", action: { manager.backupKey() })
                                    .disabled(manager.isRunning)
                                
                                ToolButton(icon: "arrow.up.doc", title: "Restore", action: { manager.restoreKey() })
                                    .disabled(manager.isRunning)
                                
                                ToolButton(icon: "arrow.triangle.2.circlepath", title: "Update Core", action: {
                                    manager.updateNode(maxClients: maxClients, bandwidth: bandwidth)
                                })
                                .disabled(manager.isUpdating)
                            }
                            
                            Button(action: { showHelpSheet = true }) { Label("Help & Guide", systemImage: "questionmark.circle").frame(maxWidth: .infinity) }
                                .buttonStyle(.bordered).controlSize(.small)
                            Button(action: { showUninstallAlert = true }) { Label("Uninstall", systemImage: "trash").foregroundColor(.red).frame(maxWidth: .infinity) }
                                .buttonStyle(.plain).padding(.top, 5).disabled(manager.isRunning)
                        }
                    }
                    .padding(.horizontal, 5)
                }
                Spacer()
                HStack(spacing: 8) {
                    Circle().fill(statusColor).frame(width: 8, height: 8).shadow(color: statusColor.opacity(0.6), radius: 4)
                    VStack(alignment: .leading) {
                        Text(manager.containerStatus).font(.caption).bold().foregroundColor(.primary)
                        Text(manager.healthStatus).font(.caption2).foregroundColor(.secondary)
                    }
                }
                .padding(10).background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.2)))
                .onTapGesture {
                    if manager.containerStatus == "Running" && manager.healthStatus == "Healthy" {
                        showStartSuccessAlert = true
                    }
                }
            }
            .padding().frame(width: 250).background(Color(nsColor: .windowBackgroundColor))
            
            // MAIN CONTENT
            VStack(spacing: 0) {
                // Header: Node ID
                HStack {
                    Image(systemName: "key.horizontal").foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("NODE IDENTITY").font(.caption2).fontWeight(.bold).foregroundColor(.secondary)
                        HStack{
                            Text(manager.nodeID).font(.system(.subheadline, design: .monospaced)).fontWeight(.medium)
                                .foregroundColor(manager.nodeID.contains("Invalid") ? .red : .primary).textSelection(.enabled).lineLimit(1)
                            Button(action: {
                                manager.getRawPrivateKey { key in
                                    if let validKey = key {
                                        let qrView = QRCodeView(privateKey: validKey)
                                        let controller = NSHostingController(rootView: qrView)
                                        let window = NSWindow(contentViewController: controller)
                                        window.title = "Ryve Share"
                                        window.styleMask = [.titled, .closable]
                                        window.center()
                                        let controller2 = NSWindowController(window: window)
                                        controller2.showWindow(nil)
                                    }
                                }
                            }) {
                                Label("Claim rewards", systemImage: "qrcode")
                            }
                            .buttonStyle(.bordered).controlSize(.small).disabled(!manager.isRunning)
                        }
                    }
                    Spacer()
                    Button(action: { manager.fetchNodeID() }) { Image(systemName: "arrow.clockwise").font(.body) }.buttonStyle(.borderless)
                }
                .padding().background(Color(nsColor: .controlBackgroundColor)).overlay(Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.1)), alignment: .bottom)
                
                // Stats Area
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("System Overview").font(.headline).padding(.horizontal).padding(.top)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            
                            CompactStatCard(title: "Uptime", value: manager.uptime, icon: "clock.fill", color: .green)
                            CompactStatCard(title: "CPU Load", value: manager.cpuUsage, icon: "cpu", color: .orange)
                            CompactStatCard(title: "RAM Usage", value: manager.memUsage, icon: "memorychip", color: .purple)
                            
                        }
                        .padding(.horizontal)
                        Text("Users Overview").font(.headline).padding(.horizontal)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            
                            CompactStatCard(title: "Peak Record", value: manager.peakUsers, icon: "trophy.fill", color: .pink)
                            CompactStatCard(title: "Active Users", value: manager.onlineUsers, icon: "person.2.fill", color: .blue)
                            CompactStatCard(title: "Connecting", value: manager.connectingUsers, icon: "hourglass", color: .yellow)
                            
                        }
                        .padding(.horizontal)
                        Text("Bandwidth Overview").font(.headline).padding(.horizontal)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            
                            CompactStatCard(title: "Up Speed", value: manager.uploadSpeed, icon: "speedometer", color: .cyan)
                            CompactStatCard(title: "Down Speed", value: manager.downloadSpeed, icon: "speedometer", color: .mint)
                            
                            CompactStatCard(title: "Total Upload", value: manager.uploadTraffic, icon: "arrow.up.circle.fill", color: .gray)
                            CompactStatCard(title: "Total Down", value: manager.downloadTraffic, icon: "arrow.down.circle.fill", color: .gray)
                        }
                        .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // --- LOGS SECTION (Resizable) ---
                VStack(spacing: 0) {
                    // 1. Resize Handle
                    if isLogsExpanded {
                        ZStack {
                            Rectangle().fill(Color(nsColor: .controlBackgroundColor)).frame(height: 10)
                            RoundedRectangle(cornerRadius: 2.5).fill(Color.gray.opacity(0.4)).frame(width: 40, height: 5)
                        }
                        .contentShape(Rectangle())
                        .onHover { inside in
                            if inside { NSCursor.resizeUpDown.push() } else { NSCursor.pop() }
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if dragStartHeight == 0 { dragStartHeight = logsHeight }
                                    let newHeight = dragStartHeight - value.translation.height
                                    if newHeight > 100 && newHeight < 600 {
                                        logsHeight = newHeight
                                    }
                                }
                                .onEnded { _ in dragStartHeight = 0 }
                        )
                        Divider()
                    } else {
                        Divider()
                    }
                    
                    // 2. Log Header
                    HStack {
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isLogsExpanded.toggle() } }) {
                            HStack(spacing: 5) {
                                Image(systemName: isLogsExpanded ? "chevron.down" : "chevron.up")
                                    .font(.caption).bold()
                                Text("System Logs").font(.headline)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 10)
                        
                        Spacer()
                        
                        Button(action: { let pb = NSPasteboard.general; pb.clearContents(); pb.setString(manager.logs, forType: .string) }) {
                            Label("Copy Logs", systemImage: "doc.on.doc").font(.caption)
                        }.buttonStyle(.bordered).controlSize(.small)
                    }
                    .padding(.horizontal).padding(.vertical, 8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    
                    if isLogsExpanded {
                        ScrollViewReader { proxy in
                            ScrollView(.vertical) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(manager.logs).font(.system(size: 11, weight: .regular, design: .monospaced))
                                        .frame(maxWidth: .infinity, alignment: .leading).padding(10).foregroundColor(.green)
                                        .textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                                    Color.clear.frame(height: 1).id("bottom")
                                }
                            }
                            .background(Color.black).cornerRadius(8)
                            .padding(.horizontal).padding(.bottom, 10)
                            .frame(height: logsHeight)
                            .onChange(of: manager.logs) { _ in withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } }
                        }
                        .background(Color(nsColor: .controlBackgroundColor))
                    }
                }
            }
        }
        .frame(minWidth: 950, minHeight: 700)
        .sheet(isPresented: $showHelpSheet) { HelpView() }
        .alert(isPresented: $showUninstallAlert) {
            Alert(title: Text("Uninstall?"), message: Text("Cannot be undone."), primaryButton: .destructive(Text("Uninstall")) { manager.uninstall() }, secondaryButton: .cancel())
        }
        .onChange(of: manager.healthStatus) { newStatus in
            if newStatus == "Healthy" && manager.containerStatus == "Running" && !hasShownStartAlert {
                hasShownStartAlert = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showStartSuccessAlert = true
                }
            }
        }
        .alert(isPresented: $showStartSuccessAlert) {
            Alert(
                title: Text("Conduit Started Successfully! 🚀"),
                message: Text("Everything is running smoothly.\n\nPlease note: It may take 1 to 24 hours for users to connect to your node. Be patient!"),
                dismissButton: .default(Text("Got it"))
            )
        }
    }
    
    var statusColor: Color {
        if manager.containerStatus.lowercased().contains("run") { return .green }
        if manager.containerStatus.lowercased().contains("stop") { return .red }
        return .yellow
    }
}
