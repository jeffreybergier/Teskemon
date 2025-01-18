//
//  Created by Jeffrey Bergier on 2025/01/17.
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

import SwiftUI
import Model

extension Process {
  
  @MainActor
  internal static func status(for services: [Service],
                              on  machines: [Machine],
                              bind: Binding<[Machine.Identifier: [Service: Service.Status]]>,
                              timeout: Int = 3) async throws
  {
    // Update UI to show Processing
    for machine in machines {
      bind.wrappedValue[machine.id] = [:]
      for service in services {
        bind.wrappedValue[machine.id]![service] = .processing
      }
    }
    // Schedule Tasks
    try await withThrowingTaskGroup(of: (Machine.Identifier, Service, Service.Status).self) { group in
      for machine in machines {
        for service in services {
          group.addTask {
            let status = try await status(for: service, on: machine, with: timeout)
            return (machine.id, service, status)
          }
        }
      }
      // Update UI to show Result
      for try await (id, service, status) in group {
        bind.wrappedValue[id]![service] = status
      }
    }
  }
  
  @MainActor
  private static func status(for service: Service,
                             on machine: Machine,
                             with timeout: Int)
                             async throws -> Service.Status
  {
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
