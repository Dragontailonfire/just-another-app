//
//  ConcurrencyLimiter.swift
//  just-another-app
//
//  Created by Narayanan VK on 17/02/2026.
//

import Foundation

actor ConcurrencyLimiter {
    private let limit: Int
    private var active = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(limit: Int) {
        self.limit = limit
    }

    func acquire() async {
        if active < limit {
            active += 1
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func release() {
        active -= 1
        if !waiters.isEmpty {
            active += 1
            let waiter = waiters.removeFirst()
            waiter.resume()
        }
    }
}
