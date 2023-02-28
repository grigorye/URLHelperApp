//
//  SampleURLToAppMapper.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 06/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Foundation

extension String {
    
    fileprivate func matchingAppBundleIdentifier() -> String {
        switch self {
        case _ where hasPrefix("https://stackoverflow.com/"):
            return "org.epichrome.app.Coding"
        default:
            return "com.google.Chrome"
        }
    }
}

class SampleURLToAppMapper : URLToAppMapper {
    
    func appBundleIdentifierFor(_ url: URL) async throws -> String {
        let urlString = url.absoluteString
        let appBundleIdentifier = urlString.matchingAppBundleIdentifier()
        
        return appBundleIdentifier
    }
}
