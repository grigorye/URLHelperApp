//
//  ScriptBasedURLResolver.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 05/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Foundation
import os.log

private let log = Logger(category: "ScriptBasedURLResolver")

class ScriptBasedURLResolver : URLResolver {
    
    let fileManager = FileManager()
    let resolverScriptName = "AppBundleIdentifierAndURLForURL"
    
    var defaultResolverURL: URL {
        let scriptsDirectoryURL: URL = try! fileManager.url(for: .applicationScriptsDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let resolverURL = scriptsDirectoryURL.appendingPathComponent(resolverScriptName)
        return resolverURL
    }
    
    func preprocessResolverURL() async throws -> URL? {
        try await makeSureResolverScriptExists(resolverURL: defaultResolverURL)
    }
    
    func makeSureResolverScriptExists(resolverURL: URL) async throws -> URL? {
        let leave = Activity("Make Sure Resolver Script Exists").enter(); defer { leave() }
        log.info("Attempting to copy \(self.bundledResolverURL.path, privacy: .public)")
        log.info("Destination: \(resolverURL.standardizedFileURL.path, privacy: .public)")
        do {
            try fileManager.copyItem(at: bundledResolverURL, to: resolverURL)
            return resolverURL
        } catch {
            switch error {
            case CocoaError.fileWriteFileExists:
                log.info("The script already exists: we're done")
                return resolverURL
            case CocoaError.fileWriteNoPermission:
                log.info("User permission required")
                guard let updatedResolverURL = try await facilitateWriteAccessForURLResolverScript(at: resolverURL) else {
                    return nil
                }
                return try await makeSureResolverScriptExists(resolverURL: updatedResolverURL)
            default:
                log.error("Copy failed: \(error)")
                throw error
            }
        }
    }
    
    var bundledResolverURL: URL {
        let bundle = Bundle(for: type(of: self))
        return bundle.url(forResource: resolverScriptName, withExtension: "")!
    }
    
    func resolveURL(_ url: URL) async throws -> URLResolution? {
        guard let resolverURL = try await preprocessResolverURL() else {
            return nil
        }
        return try await resolveURLWithoutPreprocessing(url, resolverURL: resolverURL)
    }
    
    private func resolveURLWithoutPreprocessing(_ url: URL, resolverURL: URL) async throws -> URLResolution {
        let data = try await outputFromLaunching(executableURL: resolverURL, arguments: [url.absoluteString])
        let resolution = try JSONDecoder().decode(URLResolution.self, from: data)
        return resolution
    }
}
