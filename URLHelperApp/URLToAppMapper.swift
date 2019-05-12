//
//  URLToAppMapper.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 04/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Foundation

protocol URLToAppMapper {
    
    func appBundleIdentifierFor(_ url: URL, completionHandler: @escaping (Result<String, Error>) -> Void)
}

