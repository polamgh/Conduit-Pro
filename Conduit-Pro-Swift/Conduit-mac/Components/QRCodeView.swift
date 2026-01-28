//
//  QRCodeView.swift
//  Conduit-mac
//
//  Created by Ali Ghanavati on 2026-01-27.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let privateKey: String
    @State private var name: String = "Conduit-Mac"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Share Node")
                .font(.headline)
            
            TextField("Node Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
                .multilineTextAlignment(.center)
            
            if let qrImage = generateQRCode(from: generateRyveLink()) {
                Image(nsImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            } else {
                Image(systemName: "xmark.circle")
            }
            
            Text(generateRyveLink())
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 250)
                .onTapGesture {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(generateRyveLink(), forType: .string)
                }
            
            Text("Click link to copy")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 300, height: 400)
    }
    
    func generateRyveLink() -> String {
        
        let jsonString = """
        {"version":1,"data":{"key":"\(privateKey)","name":"\(name)"}}
        """
        
        if let data = jsonString.data(using: .utf8) {
            let base64 = data.base64EncodedString()
            return "network.ryve.app://(app)/conduits?claim=\(base64)"
        }
        return ""
    }
    
    func generateQRCode(from string: String) -> NSImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            let rep = NSCIImageRep(ciImage: scaledImage)
            let nsImage = NSImage(size: rep.size)
            nsImage.addRepresentation(rep)
            return nsImage
        }
        return nil
    }
}
