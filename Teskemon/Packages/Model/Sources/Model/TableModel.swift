//
//  Created by Jeffrey Bergier on 2025/01/15.
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

public struct TableModel: Codable, Sendable {
  
  public var tailscale: Tailscale?
  public var selection = Set<Machine.Identifier>()
  public var machines  = [Machine]()
  public var lookUp    = [Machine.Identifier: Machine]()
  public var users     = [Machine.Identifier: User]()
  public var status    = [Machine.Identifier: [Service: Service.Status]]()
  public var isShowingInfoPanel = Set<Machine.Identifier>()
  
  public init() {}
  
  public func machine(for id: Machine.Identifier) -> Machine {
    return self.lookUp[id]!
  }
    
  public func status(for service: Service, on id: Machine.Identifier) -> Service.Status {
    return self.status[id]?[service] ?? .unknown
  }
  
  public func url(for service: Service, on id: Machine.Identifier) -> URL {
    return URL(string: "\(service.protocol)://\(self.machine(for: id).url):\(service.port)")!
  }
  
  public func selectedMachines() -> [Machine] {
    let selectedMachines = self.selection.map { self.machine(for: $0) }
    if selectedMachines.isEmpty {
      return Array(self.lookUp.values)
    } else {
      return selectedMachines
    }
  }
  
  public init(data: Data) throws {
    let model = try JSONDecoder().decode(JSON.TailscaleCLI.self, from: data)
    let tailscale = Tailscale(version: model.Version,
                              versionUpToDate: model.ClientVersion?.runningLatest ?? false,
                              tunnelingEnabled: model.TUN,
                              backendState: model.BackendState,
                              haveNodeKey: model.HaveNodeKey,
                              health: model.Health,
                              magicDNSSuffix: model.MagicDNSSuffix,
                              currentTailnet: model.CurrentTailnet,
                              selfNodeID: .init(rawValue: model.Self.ID),
                              selfUserID: .init(rawValue: model.Self.UserID))
    let users = Dictionary<Machine.Identifier, User>(
      uniqueKeysWithValues: model.User?.map { (.init(rawValue: $0), $1) } ?? []
    )
    
    let modelMachines = ([model.Self] + (model.Peer.map { Array($0.values) } ?? [])).sorted { $0.ID < $1.ID }
    let machines = modelMachines.map { Machine($0, selfID: tailscale.selfNodeID) }
    
    self.lookUp = Dictionary(uniqueKeysWithValues: machines.flatMap { machine in
      return [(machine.id, machine)] + (machine.subnetRoutes?.map { ($0.id, $0) } ?? [])
    })
    self.tailscale = tailscale
    self.machines = machines
    self.users = users
  }
}
