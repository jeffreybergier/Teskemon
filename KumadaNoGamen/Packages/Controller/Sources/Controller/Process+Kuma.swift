//
//  Created by Jeffrey Bergier on 2025/01/12.
//  Copyright © 2025 Saturday Apps.
//
//  This file is part of KumadaNoGamen, a macOS App.
//
//  KumadaNoGamen is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  KumadaNoGamen is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with KumadaNoGamen.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

extension Process {
  internal static func execute(url: URL = URL(fileURLWithPath: "/usr/bin/env"),
                               arguments: [String]) async throws
                               -> (exitCode: Int, stdOut: Data, errOut: Data)
  {
    try await withCheckedThrowingContinuation { continuation  in
      let tempURL   = URL(fileURLWithPath: NSTemporaryDirectory())
      let stdOutURL = tempURL.appendingPathComponent("com.saturdayapps.kumadanogamen." + UUID().uuidString + ".stdout", isDirectory: false)
      let stdErrURL = tempURL.appendingPathComponent("com.saturdayapps.kumadanogamen." + UUID().uuidString + ".stderr", isDirectory: false)
      FileManager.default.createFile(atPath: stdOutURL.path(), contents: nil)
      FileManager.default.createFile(atPath: stdErrURL.path(), contents: nil)
      
      do {
        let task = Process()
        let stdOutHandle = try FileHandle(forWritingTo: stdOutURL)
        let stdErrHandle = try FileHandle(forWritingTo: stdErrURL)
        
        task.executableURL    = url
        task.arguments        = arguments
        task.standardOutput   = stdOutHandle
        task.standardError    = stdErrHandle
        task.qualityOfService = .userInitiated
        
        task.terminationHandler = { task in
          do {
            try stdOutHandle.close()
            try stdErrHandle.close()
            let stdOut = try Data(contentsOf: stdOutURL)
            let errOut = try Data(contentsOf: stdErrURL)
            try FileManager.default.removeItem(at: stdOutURL)
            try FileManager.default.removeItem(at: stdErrURL)
            continuation.resume(returning: (Int(task.terminationStatus), stdOut, errOut))
          } catch {
            continuation.resume(throwing: error)
          }
        }
        
        try task.run()
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }
}
