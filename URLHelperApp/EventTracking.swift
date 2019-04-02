//
//  EventTracking.swift
//  URLHelperApp
//
//  Created by Grigory Entin on 3/10/19.
//  Copyright © 2019 Grigory Entin. All rights reserved.
//

protocol Action {
    associatedtype Input
    associatedtype SuccessResult
    associatedtype FailureResult
}

enum ActionEvent<T: Action> {
    case will(T, with: T.Input)
    case succeeded(T, with: T.SuccessResult)
    case failed(T, due: T.FailureResult)
}

func track<T>(_ event: ActionEvent<T>) {
    print(event)
}
func track<T>(will action: T, with input: T.Input) where T: Action {
    let event = ActionEvent<T>.will(action, with: input)
    print(event)
}
func track<T>(succeeded action: T, with result: T.SuccessResult) where T: Action {
    let event = ActionEvent<T>.succeeded(action, with: result)
    print(event)
}
func track<T>(failed action: T, due: T.FailureResult) where T: Action {
    let event = ActionEvent<T>.failed(action, due: due)
    print(event)
}

