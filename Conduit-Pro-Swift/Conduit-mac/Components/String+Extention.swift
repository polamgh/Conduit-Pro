//
//  String+Extention.swift
//  Conduit-mac
//
//  Created by Ali Ghanavati on 2026-01-28.
//

import Foundation


var appVersion: String {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    return "v\(version) • #FreeIran"
}
