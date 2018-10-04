//
//  URLToAppMapper.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 04/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Foundation

protocol URLToAppMapper {
    
    func appBundleIdentifierFor(_ url: URL) -> String
}

extension String {
    
    fileprivate func matchingAppBundleIdentifier() -> String {
        switch self {
        case _ where hasPrefix("https://stackoverflow.com"):
            return "org.epichrome.app.Coding"
        default:
            return "com.google.Chrome"
        }
    }
}

class URLToAppMapperImp : URLToAppMapper {
    
    func appBundleIdentifierFor(_ url: URL) -> String {
        let urlString = url.absoluteString

        return urlString.matchingAppBundleIdentifier()
    }
}
