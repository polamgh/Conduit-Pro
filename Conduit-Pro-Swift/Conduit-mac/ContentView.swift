//
//  ContentView.swift
//  Conduit-mac
//
//  Created by Ali Ghanavati on 2026-01-27.
//

import SwiftUI

struct ContentView: View {
    @StateObject var manager = DockerManager()
    @AppStorage("savedMaxClients") private var maxClients = "200"
    @AppStorage("savedBandwidth") private var bandwidth = "5"
    @State private var showUninstallAlert = false
    @State private var showHelpSheet = false
    
    var body: some View {
        if !manager.isDockerRunning || !manager.isDockerInstalled {
            DockerSetupView(manager: manager)
        } else {
            MainDashboard(manager: manager, maxClients: $maxClients, bandwidth: $bandwidth, showUninstallAlert: $showUninstallAlert, showHelpSheet: $showHelpSheet)
        }
    }
}










