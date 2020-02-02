//
//  ScriptBasedURLToAppMapper.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 05/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import GETracing
import Then
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
    
    func appBundleIdentifierFor(_ url: URL, completionHandler: @escaping (Result<String, Error>) -> Void) {
        enum Error : Swift.Error {
            case badTerminationReason(Process.TerminationReason)
            case badTerminationStatus(Int32)
        }
        let standardOutputPipe = Pipe()
        let standardErrorPipe = Pipe()
        let process = Process().then {
            $0.executableURL = instantiatedResolverURL
            $0.arguments = [url.absoluteString]
            $0.standardOutput = standardOutputPipe
            $0.standardError = standardErrorPipe
            $0.terminationHandler = { process in
                let standardErrorData = standardErrorPipe.fileHandleForReading.readDataToEndOfFile()
				x$(.multiline(standardErrorData))
                let terminationReason = process.terminationReason
                guard case .exit = terminationReason else {
                    completionHandler(.failure(Error.badTerminationReason(terminationReason)))
                    return
                }
                let terminationStatus = process.terminationStatus
                guard 0 == terminationStatus else {
                    completionHandler(.failure(Error.badTerminationStatus(terminationStatus)))
                    return
                }
                let data = standardOutputPipe.fileHandleForReading.readDataToEndOfFile()
                let appBundleIdentifier = String(data: data, encoding: .utf8)!.trimmingCharacters(in: .controlCharacters)
                completionHandler(.success(appBundleIdentifier))
            }
        }
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            completionHandler(.failure(error))
        }
    }
}
