//
//  DockerSetupView.swift
//  Conduit-mac
//
//  Created by Ali Ghanavati on 2026-01-28.
//

import SwiftUI

struct DockerSetupView: View {
    @ObservedObject var manager: DockerManager
    
    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 70))
                .foregroundColor(.yellow)
                .shadow(radius: 5)
            
            VStack(spacing: 5) {
                Text("Docker Required")
                    .font(.largeTitle)
                    .bold()
                Text("To run this application, Docker Desktop must be running.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            if !manager.isDockerInstalled {
                VStack(spacing: 15) {
                    Text("Docker Desktop is not installed.")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("Please download and install it first.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: { manager.downloadDocker() }) {
                        Label("Download & Install Docker", systemImage: "arrow.down.circle.fill")
                            .font(.headline)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            } else {
                VStack(spacing: 15) {
                    Text("Docker Desktop is installed but stopped.")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Button(action: { manager.openDockerApp() }) {
                        Label("Open Docker Desktop", systemImage: "play.circle.fill")
                            .font(.headline)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.blue)
                }
            }
            
            Button("Check Status Again") {
                manager.checkPrerequisites()
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            .foregroundColor(.gray)
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
