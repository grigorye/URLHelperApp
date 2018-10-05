//
//  URLToAppMapper.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 04/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Result
import Foundation

typealias _Result<T> = Result<T, AnyError>

protocol URLToAppMapper {
    
    typealias Result<T> = _Result<T>
    
    func appBundleIdentifierFor(_ url: URL, completionHandler: @escaping (Result<String>) -> Void)
}

