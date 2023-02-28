import GETracing
import Then
import Foundation

func outputFromLaunching(executableURL: URL, arguments: [String]) async throws -> Data {
    try await withCheckedThrowingContinuation { c in
        enum Error : Swift.Error {
            case badTerminationReason(Process.TerminationReason)
            case badTerminationStatus(Int32)
        }
        let standardOutputPipe = Pipe()
        let standardErrorPipe = Pipe()
        
        let terminationHandler = { (process: Process) in
            let standardErrorData = standardErrorPipe.fileHandleForReading.readDataToEndOfFile()
            x$(.multiline(standardErrorData))
            let terminationReason = process.terminationReason
            guard case .exit = terminationReason else {
                throw Error.badTerminationReason(terminationReason)
            }
            let terminationStatus = process.terminationStatus
            guard 0 == terminationStatus else {
                throw Error.badTerminationStatus(terminationStatus)
            }
            return standardOutputPipe.fileHandleForReading.readDataToEndOfFile()
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
            c.resume(throwing: error)
        }
    }
}
