//
//  ScriptBasedURLToAppMapper.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 05/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Result
import Then
import Foundation

class ScriptBasedURLToAppMapper : URLToAppMapper {
    
    let fileManager = FileManager()
    let resolverScriptName = "ApplicationBundleIdentiferForURL"
    
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
    
    func appBundleIdentifierFor(_ url: URL, completionHandler: @escaping (Result<String, AnyError>) -> Void) {
        enum Error : Swift.Error {
            case badTerminationReason(Process.TerminationReason)
            case badTerminationStatus(Int32)
        }
        let pipe = Pipe()
        let process = Process().then {
            $0.executableURL = instantiatedResolverURL
            $0.arguments = [url.absoluteString]
            $0.standardOutput = pipe
            $0.terminationHandler = { process in
                let terminationReason = process.terminationReason
                guard case .exit = terminationReason else {
                    completionHandler(.failure(AnyError(Error.badTerminationReason(terminationReason))))
                    return
                }
                let terminationStatus = process.terminationStatus
                guard 0 == terminationStatus else {
                    completionHandler(.failure(AnyError(Error.badTerminationStatus(terminationStatus))))
                    return
                }
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let appBundleIdentifier = String(data: data, encoding: .utf8)!.trimmingCharacters(in: .controlCharacters)
                completionHandler(.success(appBundleIdentifier))
            }
        }
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            completionHandler(.failure(AnyError(error)))
        }
    }
}
