//
//  SampleURLResolver.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 06/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Foundation

extension URL {
    
    fileprivate func matchingURLResolution() -> URLResolution {
        switch self {
        case _ where absoluteString.hasPrefix("https://stackoverflow.com/"):
            return URLResolution(finalURL: self, appBundleIdentifier: "org.epichrome.app.Coding")
        default:
            return URLResolution(finalURL: self, appBundleIdentifier: "com.google.Chrome")
        }
    }
}

class SampleURLResolver : URLResolver {
    
    func resolveURL(_ url: URL) async throws -> URLResolution? {
        url.matchingURLResolution()
    }
}
