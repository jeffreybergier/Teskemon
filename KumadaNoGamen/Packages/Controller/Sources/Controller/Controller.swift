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

import SwiftUI
import Model
import Umbrella

@MainActor
@propertyWrapper
public struct Controller: DynamicProperty {
  
  public struct Value: Codable {
    public var tailscale:  Tailscale?
    public var machineIDs: [Machine.Identifier] = []
    public var machines:   [Machine.Identifier: Machine] = [:]
    public var users:      [Machine.Identifier: User] = [:]
    public var services:   [Machine.Identifier: [Service: Service.Status]] = [:]
    public var isUpdatingMachines = false
    public var isUpdatingServices = false
  }
  
  @JSBSceneStorage("ControllerValue") private var storage: Value = Value()
  @AppStorage("TailscaleLocation") private var location: String = "/Applications/Tailscale.app/Contents/MacOS/Tailscale"
                                                            //  = "/usr/local/bin/tailscale"
  @Services private var services
  
  public init() {}
  
  public var wrappedValue: Value {
    return self.storage
  }
  
  public func resetData() {
    self.storage = .init()
  }
  
  public func updateMachines() async throws {
    NSLog("Controller: updateMachines: Start")
    self.storage.isUpdatingMachines = true
    let value = try await type(of: self).getTailscale(self.location)
    self.storage.tailscale = value.tailscale
    self.storage.machineIDs = Array(value.machines.keys.sorted(by: { $0.rawValue > $1.rawValue }))
    self.storage.machines = value.machines
    self.storage.users = value.users
    self.storage.isUpdatingMachines = false
    NSLog("Controller: updateMachines: End")
  }
  
  public func updateServices() async throws {
    NSLog("Controller: updateServices: Start")
    self.storage.isUpdatingServices = true
    try await type(of: self).getStatus(for: self.services,
                                       on: Array(self.storage.machines.values),
                                       bind: self.$storage.services)
    self.storage.isUpdatingServices = false
    NSLog("Controller: updateServices: End")
  }
}

extension Controller {
  
  internal static func getTailscale(_ location: String) async throws -> Tailscale.Refresh {
    let data = try await Process.execute(arguments: [location, "status", "--json"]).stdOut
    return try Tailscale.Refresh.new(data: data)
  }
  
  internal static func getStatus(for services: [Service],
                                 on  machines: [Machine],
                                 bind: Binding<[Machine.Identifier: [Service: Service.Status]]>,
                                 timeout: Int = 3)
                                 async throws
  {
    // Iterate over every machine
    for machine in machines {
      // Prepare the binding to accept values for this machine
      let id = machine.id
      if bind.wrappedValue[id] == nil { bind.wrappedValue[id] = [:] }
      
      // Iterate over every service
      for service in services {
        // Mark status as processing while network activity happens
        bind.wrappedValue[id]![service] = .processing
        
        // Perform network request
        let arguments: [String] = [
          "/usr/bin/nc",
          "-zv",
          "-G \(timeout)",
          "-w \(timeout)",
          machine.url,
          "\(service.port)"
        ]
        let result = try await Process.execute(arguments: arguments)
        // Not sure why Netcat puts the results in standard error, but it does
        let output = String(data: result.errOut, encoding: .utf8)!
        
        // Check result and update status
        if output.hasSuffix("succeeded!\n") {
          bind.wrappedValue[id]![service] = .online
        } else if output.hasSuffix("refused\n") {
          bind.wrappedValue[id]![service] = .offline
        } else if output.hasSuffix("Operation timed out\n") {
          bind.wrappedValue[id]![service] = .error
        } else {
          assertionFailure()
          bind.wrappedValue[id]![service] = .error
        }
      }
    }
  }
}
