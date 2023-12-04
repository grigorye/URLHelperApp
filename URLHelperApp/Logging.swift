//
//  Logging.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 02/12/2023.
//

import Foundation
import os.log

private let logSubsystem = Bundle.main.bundleIdentifier!

extension Logger {
    init(category: String) {
        self.init(subsystem: logSubsystem, category: category)
    }
}
