//
//  HelpView.swift
//  Conduit-mac
//
//  Created by Ali Ghanavati on 2026-01-28.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Conduit Pro Guide")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    GuideSection(title: "1. Prerequisites", content: "• Docker Desktop must be installed and running.\n• If building from source, remove 'App Sandbox' capability in Xcode.")
                    
                    GuideSection(title: "2. Configuration", content: "• Set your desired Max Clients and Bandwidth limits.\n• Click 'Start Service' to automatically deploy the container.")
                    
                    GuideSection(title: "3. Node Identity", content: "• The Node ID is your server's unique identity.\n• IMPORTANT: Use the 'Backup' button to save your private key safely.")
                    
                    GuideSection(title: "4. Connection Delay (Important)", content: "• After starting the service, it is normal to see 0 users initially.\n• Please wait **1 to 24 hours** for the network to discover your node and for users to start connecting. Be patient!")
                }
                .padding()
            }
        }
        .frame(width: 400, height: 550)
    }
}

struct GuideSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).foregroundColor(.blue)
            Text(content).font(.body).foregroundColor(.secondary)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}
