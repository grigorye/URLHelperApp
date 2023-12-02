//
//  ScriptBasedURLToAppMapper.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 05/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Foundation

class ScriptBasedURLToAppMapper : URLToAppMapper {
    
    let fileManager = FileManager()
    let resolverScriptName = "AppBundleIdentifierForURL"
    
    var resolverURL: URL {
        let scriptsDirectoryURL: URL = try! fileManager.url(for: .applicationScriptsDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let resolverURL = scriptsDirectoryURL.appendingPathComponent(resolverScriptName)
        return resolverURL
    }
    
    var instantiatedResolverURL: URL {
        try? fileManager.copyItem(at: bundledResolverURL, to: resolverURL)
        return resolverURL
    }
    
    var bundledResolverURL: URL {
        let bundle = Bundle(for: type(of: self))
        return bundle.url(forResource: resolverScriptName, withExtension: "")!
    }
    
    func appBundleIdentifierFor(_ url: URL) async throws -> String {
        let data = try await outputFromLaunching(executableURL: instantiatedResolverURL, arguments: [url.absoluteString])
        let appBundleIdentifier = String(data: data, encoding: .utf8)!.trimmingCharacters(in: .controlCharacters)
        return appBundleIdentifier
    }
}
