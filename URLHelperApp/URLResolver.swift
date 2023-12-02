//
//  URLResolver.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 04/10/2018.
//  Copyright © 2018 Grigory Entin. All rights reserved.
//

import Foundation

struct URLResolution: Decodable {
    let finalURL: URL
    let appBundleIdentifier: String
}

protocol URLResolver {
    func resolveURL(_ url: URL) async throws -> URLResolution?
}
