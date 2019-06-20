//
//  EventTracking.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 3/10/19.
//  Copyright © 2019 Grigory Entin. All rights reserved.
//

import os.log

protocol Action {
    associatedtype Input
    associatedtype SuccessResult
    associatedtype FailureResult
}

enum ActionEvent<T: Action> {
    case will(T.Type, with: T.Input)
    case succeeded(T.Type, with: T.SuccessResult)
    case failed(T.Type, due: T.FailureResult)
}

func track<T>(will action: T, with input: T.Input) where T: Action {
    let event = ActionEvent<T>.will(type(of: action), with: input)
    track(event)
}
func track<T>(succeeded action: T, with result: T.SuccessResult) where T: Action {
    let event = ActionEvent<T>.succeeded(type(of: action), with: result)
    track(event)
}
func track<T>(failed action: T, due: T.FailureResult) where T: Action {
    let event = ActionEvent<T>.failed(type(of: action), due: due)
    track(event)
}

private func track<T>(_ event: ActionEvent<T>) {
    let eventDescription = "\(event)"
    os_log("%{public}@", eventDescription)
}
