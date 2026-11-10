//
//  ProcessExitSignal.swift
//  LintStudioCore
//
//  Bridges a process's termination handler to `await` for CLIToolActor.
//

import Foundation

/// A one-shot bridge from `Process.terminationHandler` (a C-style callback) to
/// async `await`. It exists to replace `Process.waitUntilExit()`, whose blocking
/// wait can wedge indefinitely on a Swift-concurrency cooperative thread even
/// after the child has exited and its pipes have reached EOF — a hang that
/// surfaces under many rapid back-to-back invocations and which the run timeout
/// cannot rescue (the timeout only kills the child to unblock the pipe reads).
///
/// Tolerates the resume arriving before or after the `value` access: the
/// terminated status is latched until a waiter parks, and a parked waiter is
/// resumed the instant the status arrives.
final class ProcessExitSignal: @unchecked Sendable {
    private let lock = NSLock()
    nonisolated(unsafe) private var status: Int32?
    nonisolated(unsafe) private var waiter: CheckedContinuation<Int32, Never>?

    /// Records the process's exit status, resuming a parked waiter if present.
    /// Called once, from the termination handler (on an arbitrary thread).
    nonisolated func resume(_ exitStatus: Int32) {
        lock.lock()
        if let parked = waiter {
            waiter = nil
            lock.unlock()
            parked.resume(returning: exitStatus)
        } else {
            status = exitStatus
            lock.unlock()
        }
    }

    /// The process's exit status, awaited — returning immediately if it has
    /// already terminated.
    nonisolated var value: Int32 {
        get async {
            await withCheckedContinuation { continuation in
                lock.lock()
                if let status {
                    lock.unlock()
                    continuation.resume(returning: status)
                } else {
                    waiter = continuation
                    lock.unlock()
                }
            }
        }
    }
}
