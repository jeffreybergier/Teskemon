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

public struct MachineModel: Codable, Sendable {
  
  public var tailscale: Tailscale?
  public var allIDs: [MachineIdentifier] = []
  public var selectedIDs: Set<String> = []
  public var hosts: [MachineIdentifier: HostMachine] = [:]
  public var subnets: [MachineIdentifier: SubnetMachine] = [:]
  public var users: [MachineIdentifier: User] = [:]
  public var status: [MachineIdentifier: [Service: Service.Status]] = [:]
  
  public init() {}
  
  public func machine(for id: MachineIdentifier) -> Machine {
    return (self.hosts[id] ?? self.subnets[id])!
  }
    
  public func status(for service: Service, on id: MachineIdentifier) -> Service.Status {
    return self.status[id]?[service] ?? .unknown
  }
  
  public func url(for service: Service, on id: MachineIdentifier) -> URL {
    return URL(string: "\(service.protocol)://\(self.machine(for: id).url):\(service.port)")!
  }
  
  public func selectedMachines() -> [Machine] {
    let selectedMachines = self.selectedIDs.map { self.machine(for: .init(rawValue: $0)) }
    if selectedMachines.isEmpty {
      return self.allIDs.map { self.machine(for: $0) }
    } else {
      return selectedMachines
    }
  }
}
