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
  internal static func allStatus(services: [Service],
                                 machines: [Machine],
                                 config: Scanning,
                                 bind: Binding<ServiceController.Value>)
                                 async throws
  {
    let progress = bind.wrappedValue.progress
    progress.totalUnitCount += 2
    try await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask {
        try await self.pingStatus(for: machines,
                                  config: config,
                                  bind: bind)
      }
      group.addTask {
        try await self.serviceStatus(for: services,
                                     on: machines,
                                     config: config,
                                     bind: bind)
      }
      for try await _ in group {
        progress.completedUnitCount += 1
        return ()
      }
    }
  }
  
  @MainActor
  internal static func serviceStatus(for services: [Service],
                                     on  machines: [Machine],
                                     config: Scanning,
                                     bind: Binding<ServiceController.Value>) async throws
  {
    
    // Create a single list of input so that we can batch this
    let toProcess = machines.flatMap { machine in
      services.map { service in
        (machine: machine, service: service)
      }
    }
    
    let progress = bind.wrappedValue.progress
    progress.totalUnitCount += Int64(toProcess.count)
    
    // Schedule Tasks
    for batch in toProcess.batch(into: config.batchSize) {
      try await withThrowingTaskGroup(of: (Machine.Identifier, Service, Service.Status).self)
      { group in
        for (machine, service) in batch {
          // Mark service as processing
          bind.wrappedValue[machine.id, service] = .processing
          // Schedule new tasks
          group.addTask {
            let status = try await serviceStatus(for: service,
                                                 on: machine,
                                                 config: config)
            return (machine.id, service, status)
          }
        }
        // Update UI to show Result
        for try await (id, service, status) in group {
          progress.completedUnitCount += 1
          bind.wrappedValue[id, service] = status
        }
      }
    }
  }
  
  private static func serviceStatus(for service: Service,
                                    on machine: Machine,
                                    config: Scanning)
                                    async throws -> Service.Status
  {
    let arguments: [String] = [
      "/usr/bin/nc",
      "-zv",
      "-G \(config.netcatTimeout)",
      "-w \(config.netcatTimeout)",
      machine.host,
      "\(service.port)"
    ]
    let output = try await Process.execute(arguments: arguments)
    let outputString = String(data: output.errOut, encoding: .utf8)!
    if outputString.hasSuffix("succeeded!\n") {
      NSLog("[ONLINE ] \(machine.host):\(service.port)")
      return .online
    } else if outputString.hasSuffix("refused\n") {
      NSLog("[OFFLINE] \(machine.host):\(service.port)")
      return .offline
    } else if outputString.hasSuffix("Operation timed out\n") {
      NSLog("[TIMEOUT] \(machine.host):\(service.port)")
      return .error
    } else {
      NSLog("[ERROR  ] \(machine.host):\(service.port)")
      return .error
    }
  }
  
  @MainActor
  internal static func pingStatus(for  machines: [Machine],
                                  config: Scanning,
                                  bind: Binding<ServiceController.Value>)
                                  async throws
  {
    let progress = bind.wrappedValue.progress
    progress.totalUnitCount += Int64(machines.count)
    
    for batch in machines.batch(into: config.batchSize) {
      try await withThrowingTaskGroup(of: (Machine.Identifier, Service.Status).self)
      { group in
        for machine in batch {
          // Mark service as processing
          bind.wrappedValue[machine.id] = .processing
          // Schedule new tasks
          group.addTask {
            let status = try await pingStatus(for: machine, config: config)
            return (machine.id, status)
          }
        }
        
        // Update UI to show Result
        for try await (id, status) in group {
          progress.completedUnitCount += 1
          bind.wrappedValue[id] = status
        }
      }
    }
  }
  
  private static func pingStatus(for machine: Machine,
                                 config: Scanning)
                                 async throws -> Service.Status
  {
    
    /* Example ping output
     - 0 : "PING 192.168.0.104 (192.168.0.104): 56 data bytes"
     - 1 : "Request timeout for icmp_seq 0"
     - 2 : "Request timeout for icmp_seq 1"
     - 3 : "Request timeout for icmp_seq 2"
     - 4 : "64 bytes from 192.168.0.104: icmp_seq=0 ttl=64 time=3098.041 ms"
     - 5 : "64 bytes from 192.168.0.104: icmp_seq=1 ttl=64 time=3092.916 ms"
     - 6 : "64 bytes from 192.168.0.104: icmp_seq=2 ttl=64 time=3057.906 ms"
     - 7 : "64 bytes from 192.168.0.104: icmp_seq=3 ttl=64 time=3049.467 ms"
     - 8 : "64 bytes from 192.168.0.104: icmp_seq=4 ttl=64 time=3091.692 ms"
     - 9 : "Request timeout for icmp_seq 8"
     - 10 : "Request timeout for icmp_seq 9"
     - 11 : "Request timeout for icmp_seq 10"
     - 12 : "--- 192.168.0.104 ping statistics ---"
     - 13 : "12 packets transmitted, 5 packets received, 58.3% packet loss"   <--- Select this row
     - 14 : "round-trip min/avg/max/stddev = 3049.467/3078.004/3098.041/20.147 ms"
     */
    let arguments: [String] = [
      "/sbin/ping",
      "-c \(config.pingCount)",
      machine.host,
    ]
    let output = try await Process.execute(arguments: arguments)
    let outputString = String(data: output.stdOut, encoding: .utf8) ?? ""
    // "12 packets transmitted, 5 packets received, 58.3% packet loss"
    let regex = try Regex(#", (\d+\.\d+)% packet loss"#)
    let matchString = outputString.firstMatch(of: regex)?.output.last?.substring ?? ""
    let matchNumber = Double(matchString) ?? 100
    return matchNumber > config.pingLoss ? .offline : .online
  }
}

extension Array {
  func batch(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size).map {
      Array(self[$0..<Swift.min($0 + size, count)])
    }
  }
}
