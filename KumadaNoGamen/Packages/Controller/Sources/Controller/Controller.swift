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
  @AppStorage("TailscaleLocation") private var location: String = "/usr/local/bin/tailscale"
  @Services private var services
  
  public init() {}
  
  public var wrappedValue: Value {
    return self.storage
  }
  
  public func updateMachines() async throws {
    self.storage.isUpdatingMachines = true
    let value = try await type(of: self).getTailscale(self.location)
    self.storage.tailscale = value.tailscale
    self.storage.machineIDs = Array(value.machines.keys.sorted(by: { $0.rawValue > $1.rawValue }))
    self.storage.machines = value.machines
    self.storage.users = value.users
    self.storage.isUpdatingMachines = false
  }
  
  public func updateServices() async throws {
    self.storage.isUpdatingServices = true
    self.storage.services = try await type(of: self).getStatus(for: self.services,
                                                               on: self.storage.machines)
    self.storage.isUpdatingServices = false
  }
}

extension Controller {
  
  internal static func getTailscale(_ location: String) async throws -> Tailscale.Refresh {
    let data = try await Process.execute(arguments: [location, "status", "--json"]).stdOut
    return try Tailscale.Refresh.new(data: data)
  }
  
  internal static func getStatus(for services: [Service],
                                 on  machines: [Machine.Identifier: Machine]) async throws
                                 -> [Machine.Identifier: [Service: Service.Status]]
  {
    guard !machines.isEmpty, !services.isEmpty else { return [:] }
    let timeout = 3
    var output: [Machine.Identifier: [Service: Service.Status]] = [:]
    for (id, node) in machines {
      var status: [Service: Service.Status] = [:]
      for service in services {
        let arguments: [String] = ["/usr/bin/nc", "-zv", "-G \(timeout)", "-w \(timeout)", node.url, String(describing: service.port)]
        let result = try await Process.execute(arguments: arguments)
        // Not sure why the output always comes through Standard Error with NC
        let output = String(data: result.errOut, encoding: .utf8)!
        if output.hasSuffix("succeeded!\n") {
          NSLog("OPEN: \(arguments)")
          status[service] = .online
        } else if output.hasSuffix("refused\n") {
          NSLog("CLSD: \(arguments)")
          status[service] = .offline
        } else if output.hasSuffix("Operation timed out\n") {
          NSLog("TMOT: \(arguments)")
          status[service] = .error
        } else {
          assertionFailure()
          NSLog("ERRR: \(arguments)")
          status[service] = .error
        }
      }
      output[id] = status
    }
    return output
  }
}
