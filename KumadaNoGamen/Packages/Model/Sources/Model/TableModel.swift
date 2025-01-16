//
//  Created by Jeffrey Bergier on 2025/01/15.
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

public struct TableModel: Codable {
  
  public var tailscale: Tailscale?
  public var ids:      [MachineIdentifier] = []
  public var hosts:    [MachineIdentifier: HostMachine] = [:]
  public var subnets:  [MachineIdentifier: SubnetMachine] = [:]
  public var users:    [MachineIdentifier: User] = [:]
  public var services: [MachineIdentifier: [Service: Service.Status]] = [:]
  
  public init() {}
  
  public var allMachines: [Machine] {
    return Array(self.hosts.values) + Array(self.subnets.values)
  }
  
  public func machine(for id: MachineIdentifier) -> Machine {
    return (self.hosts[id] ?? self.subnets[id])!
  }
  
  public func status(for service: Service, on id: MachineIdentifier) -> Service.Status {
    return self.services[id]?[service] ?? .unknown
  }
  
  public func url(for service: Service, on id: MachineIdentifier) -> URL {
    return URL(string: "\(service.protocol)://\(self.machine(for: id).url):\(service.port)")!
  }
}
