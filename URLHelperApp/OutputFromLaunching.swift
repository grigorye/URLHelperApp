import Foundation
import os.log

private let log = Logger(category: "OutputFromLaunching")

func outputFromLaunching(executableURL: URL, arguments: [String]) async throws -> Data {
    let leave = Activity("Shell Output").enter(); defer { leave() }
    let captureResultActivity = Activity("Capture Result")
    log.info("Executable: \(executableURL.standardizedFileURL.path, privacy: .public)")
    log.info("Arguments: \(arguments)")
    return try await withCheckedThrowingContinuation { c in
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let terminationHandler = { (process: Process) in
            let leave = captureResultActivity.enter(); defer { leave() }
            let stdout = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stderr = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            log.info("Stdout: \(formatted(output: stdout), privacy: .public)")
            let terminationReason = process.terminationReason
            guard case .exit = process.terminationReason else {
                log.error("Stderr: \(formatted(output: stderr), privacy: .private)")
                log.error("Failed with reason: \(String(describing: terminationReason))")
                throw OutputFromLaunchingError.badTerminationReason(terminationReason)
            }
            let terminationStatus = process.terminationStatus
            guard 0 == terminationStatus else {
                log.error("Stderr: \(formatted(output: stderr), privacy: .private)")
                log.error("Failed with exit status: \(terminationStatus)")
                throw OutputFromLaunchingError.badTerminationStatus(terminationStatus)
            }
            return stdout
        }
        let process = {
            $0.executableURL = executableURL
            $0.arguments = arguments
            $0.standardOutput = stdoutPipe
            $0.standardError = stderrPipe
            $0.terminationHandler = { process in
                let r = Result { try terminationHandler(process) }
                c.resume(with: r)
            }
            return $0
        } (Process())
        do {
            try process.run()
            log.info("Launch succeeded")
        } catch {
            log.error("Launch failed: \(error)")
            c.resume(throwing: error)
        }
    }
}

enum OutputFromLaunchingError: Error {
    case badTerminationReason(Process.TerminationReason)
    case badTerminationStatus(Int32)
}

private func formatted(output data: Data) -> String {
    guard let utf8 = String(data: data, encoding: .utf8) else {
        return "<non-decodable-from-utf8>"
    }
    return """
    
    ```
    \(utf8)
    ```
    """
}
