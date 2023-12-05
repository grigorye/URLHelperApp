//
//  WriteAccessFacilitator.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 01/12/2023.
//

import AppKit
import Foundation

private let fileManager = FileManager()

private var appName: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? fileManager.displayName(atPath: Bundle.main.bundlePath)
}

func facilitateWriteAccessForURLResolverScript(at url: URL) async throws -> URL? {
    let leave = Activity("Facilitate Write Access To Resolver Script").enter(); defer { leave() }
    return try await facilitateWriteAccessViaUserInteraction(to: url, message: String(localized: "Select the location for the resolver script for \(appName)"))
}

@MainActor
func facilitateWriteAccessViaUserInteraction(to url: URL, message: String) async throws -> URL? {
    let panel = {
        $0.message = message
        $0.directoryURL = url.deletingLastPathComponent()
        $0.nameFieldStringValue = url.lastPathComponent
        $0.prompt = String(localized: "Select")
        return $0
    }(NSSavePanel())
    
    return panel.url
}
