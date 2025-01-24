//
//  Created by Jeffrey Bergier on 2025/01/17.
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

import SwiftUI
import Model

extension Process {
  
  @MainActor
  internal static func status(for services: [Service],
                              on  machines: [Machine],
                              bind: Binding<StatusController.Value>,
                              timeout: Int,
                              batchSize: Int) async throws
  {
    
    // Create a single list of input so that we can batch this
    let toProcess = machines.flatMap { machine in
      services.map { service in
        (machine: machine, service: service)
      }
    }
    
    // Schedule Tasks
    for batch in toProcess.batch(into: batchSize) {
      try await withThrowingTaskGroup(of: (Machine.Identifier, Service, Service.Status).self) { group in
        for (machine, service) in batch {
          // Mark service as processing
          bind.wrappedValue[machine.id, service] = .processing
          // Schedule new tasks
          group.addTask {
            let status = try await status(for: service, on: machine, with: timeout)
            return (machine.id, service, status)
          }
        }
        // Update UI to show Result
        for try await (id, service, status) in group {
          bind.wrappedValue[id, service] = status
        }
      }
    }
  }
  
  private static func status(for service: Service,
                             on machine: Machine,
                             with timeout: Int)
  async throws -> Service.Status
  {
    // TODO: Switch to tailscale netcat
    // TODO: Add support for tailscale ping
    let arguments: [String] = [
      "/usr/bin/nc",
      "-zv",
      "-G \(timeout)",
      "-w \(timeout)",
      machine.url,
      "\(service.port)"
    ]
    let output = try await Process.execute(arguments: arguments)
    let outputString = String(data: output.errOut, encoding: .utf8)!
    if outputString.hasSuffix("succeeded!\n") {
      NSLog("[ONLINE ] \(machine.url):\(service.port)")
      return .online
    } else if outputString.hasSuffix("refused\n") {
      NSLog("[OFFLINE] \(machine.url):\(service.port)")
      return .offline
    } else if outputString.hasSuffix("Operation timed out\n") {
      NSLog("[TIMEOUT] \(machine.url):\(service.port)")
      return .error
    } else {
      NSLog("[ERROR  ] \(machine.url):\(service.port)")
      NSLog("\(machine.url):\(service.port) - Error")
      return .error
    }
  }
}

extension Array {
  func batch(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size).map {
      Array(self[$0..<Swift.min($0 + size, count)])
    }
  }
}
