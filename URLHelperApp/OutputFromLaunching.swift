import Then
import Foundation
import os.log

private let log = Logger(subsystem: "OutputFromLaunching", category: "")

func outputFromLaunching(executableURL: URL, arguments: [String]) async throws -> Data {
    log.info("Executing \(executableURL.standardizedFileURL.path) with \(arguments).")
    return try await withCheckedThrowingContinuation { c in
        let standardOutputPipe = Pipe()
        let standardErrorPipe = Pipe()
        
        let terminationHandler = { (process: Process) in
            let standardErrorData = standardErrorPipe.fileHandleForReading.readDataToEndOfFile()
            log.error("Error data: \(standardErrorData).")
            let standardOutputData = standardOutputPipe.fileHandleForReading.readDataToEndOfFile()
            log.info("Output data: \(standardOutputData).")
            let terminationReason = process.terminationReason
            guard case .exit = terminationReason else {
                log.error("Exec failed. Not exited normally: \(String(describing: terminationReason)).")
                log.error("Stderr: \(String(data: standardOutputData, encoding: .utf8) ?? "null").")
                throw OutputFromLaunchingError.badTerminationReason(terminationReason)
            }
            let terminationStatus = process.terminationStatus
            guard 0 == terminationStatus else {
                log.error("Exec failed. Termination status: \(terminationStatus).")
                throw OutputFromLaunchingError.badTerminationStatus(terminationStatus)
            }
            log.info("Exec succeeded.")
            log.info("Stdout: \(String(data: standardOutputData, encoding: .utf8) ?? "<non-decodable-from-utf8>").")
            return standardOutputData
        }
        
        let process = Process().then {
            $0.executableURL = executableURL
            $0.arguments = arguments
            $0.standardOutput = standardOutputPipe
            $0.standardError = standardErrorPipe
            $0.terminationHandler = { process in
                let r = Result { try terminationHandler(process) }
                c.resume(with: r)
            }
        }
        
        do {
            try process.run()
        } catch {
            log.error("Launch failed: \(error).")
            c.resume(throwing: error)
        }
    }
}

enum OutputFromLaunchingError: Error {
    case badTerminationReason(Process.TerminationReason)
    case badTerminationStatus(Int32)
}
