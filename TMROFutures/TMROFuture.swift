//
//  Future.swift
//  TMROFutures
//
//  Created by Benji Dodgson on 11/3/19.
//  Copyright © 2019 Tomorrow Ideas. All rights reserved.
//

import Foundation

// A wrapper object that will contain a value at some time in the future.
// The contained value is intentionally not directly accessible. Interested parties can be notified when
// the value is set by assigning a callback through the observe function.
public class TMROFuture<Value> {

    fileprivate var result: Result<Value, Error>? {
        didSet {
            // Report a result whenever it is assigned
            if let result = self.result {
                self.report(result: result)
            }
        }
    }
    private var callbacks: [(Result<Value, Error>) -> Void] = []
    private var valueCallbacks: [(Value) -> Void] = []

    // Calls the callback once the future receives a result, or immediately if it already has one.
    public func observe(with callback: @escaping (Result<Value, Error>) -> Void) {
        self.callbacks.append(callback)

        // If a result has already been set, call the callback directly
        if let result = self.result {
            callback(result)
        }
    }

    // Calls the callback back once the future receives a value, or immediately if it already has one.
    // Does NOT call the callback in the event of an error.
    public func observeValue(with callback: @escaping (Value) -> Void) {
        self.valueCallbacks.append(callback)

        // If a result has already been set, call the callback directly
        if let result = self.result {
            switch result {
            case .success(let value):
                callback(value)
            case .failure:
                break
            }
        }
    }

    // Let's observers know that a result has been set.
    private func report(result: Result<Value, Error>) {
        self.callbacks.forEach { (callback) in
            callback(result)
        }

        self.valueCallbacks.forEach { (callback) in
            switch result {
            case .success(let value):
                callback(value)
            case .failure:
                break
            }
        }
    }
}

// A future value that can be fulfilled. Promises are a subclass of futures that allow you to set the
// result or pass in an error, thus alerting any observers.
public final class TMROPromise<Value>: TMROFuture<Value> {

    public init(value: Value? = nil) {
        super.init()

        // If the value was already known at the time the promise was constructed,
        // we can report the value directly
        if let value = value {
            self.result = Result.success(value)
        }
    }

    public init(error: Error) {
        super.init()
        self.result = Result.failure(error)
    }

    public func resolve(with value: Value) {
        self.result = .success(value)
    }

    public func reject(with error: Error) {
        self.result = .failure(error)
    }
}
