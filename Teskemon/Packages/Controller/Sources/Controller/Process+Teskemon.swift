//
//  Created by Jeffrey Bergier on 2025/01/12.
//  Copyright © 2025 Saturday Apps.
//
//  This file is part of Teskemon, a macOS App.
//
//  Teskemon is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Teskemon is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Teskemon.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

extension Process {
  
  internal struct Output: Sendable, Codable {
    internal let exitCode: Int
    internal let stdOut: Data
    internal let errOut: Data
  }
  
  internal static func execute(url: URL = URL(fileURLWithPath: "/usr/bin/env"),
                               arguments: [String]) async throws
  -> Output
  {
    return try await Task { try self.execute(url: url, arguments: arguments) }.value
  }
  
  internal static func execute(url: URL = URL(fileURLWithPath: "/usr/bin/env"),
                               arguments: [String]) throws
  -> Output
  {
    // Create Output Files
    let tempURL   = URL(fileURLWithPath: NSTemporaryDirectory())
    let stdOutURL = tempURL.appendingPathComponent("com.saturdayapps.Teskemon." + UUID().uuidString + ".stdout", isDirectory: false)
    let stdErrURL = tempURL.appendingPathComponent("com.saturdayapps.Teskemon." + UUID().uuidString + ".stderr", isDirectory: false)
    FileManager.default.createFile(atPath: stdOutURL.path(), contents: nil)
    FileManager.default.createFile(atPath: stdErrURL.path(), contents: nil)
    
    do {
      // Create File Handles
      let stdOutHandle = try FileHandle(forWritingTo: stdOutURL)
      let stdErrHandle = try FileHandle(forWritingTo: stdErrURL)
      
      // Configure Task
      let task = Process()
      task.executableURL    = url
      task.arguments        = arguments
      task.standardOutput   = stdOutHandle
      task.standardError    = stdErrHandle
      task.qualityOfService = .userInitiated
      
      // Execute Task
      try task.run()
      task.waitUntilExit()
      
      // Process output
      try stdOutHandle.close()
      try stdErrHandle.close()
      let stdOut = try Data(contentsOf: stdOutURL)
      let errOut = try Data(contentsOf: stdErrURL)
      try FileManager.default.removeItem(at: stdOutURL)
      try FileManager.default.removeItem(at: stdErrURL)
      
      return .init(exitCode: Int(task.terminationStatus), stdOut: stdOut, errOut: errOut)
    } catch {
      throw error
    }
  }
}
