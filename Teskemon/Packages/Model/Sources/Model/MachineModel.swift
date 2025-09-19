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

// TODO: Refactor these models to no longer use Codable as its too fragile
public struct MachineModel: Codable {
  
  public   var isLoading: Bool = false
  public   var tailscale: Tailscale?
  public   var machines:  [Machine]
  public   var users:     [User.Identifier: User]
  internal var lookUp:    [Machine.Identifier: Machine]
  
  public enum CodingKeys: String, CodingKey {
    case tailscale, machines, users, lookUp
  }
  
  public subscript(id: Machine.Identifier) -> Machine {
    guard let machine = self.lookUp[id] else {
      NSLog("[MISSED] MachineID: \(id.rawValue)")
      return .init()
    }
    return machine
  }
  
  public func machines(for selection: Set<Machine.Identifier>) -> [Machine] {
    return selection.map { self[$0] }
  }
  
  public func allMachines() -> [Machine] {
    return Array(self.lookUp.values)
  }
  
  public func allIdentifiers() -> Set<Machine.Identifier> {
    return Set(self.lookUp.keys)
  }
  
  public init() {
    self.isLoading = false
    self.tailscale = nil
    self.machines  = []
    self.users     = [:]
    self.lookUp    = [:]
  }
  
  public init(data: Data) throws {
    let rawModel = try JSONDecoder().decode(TailscaleCLI.self, from: data)
    let tailscale = Tailscale(version:          rawModel.Version ?? "",
                              versionUpToDate:  rawModel.ClientVersion?.runningLatest ?? false,
                              tunnelingEnabled: rawModel.TUN ?? false,
                              backendState:     rawModel.BackendState ?? "",
                              haveNodeKey:      rawModel.HaveNodeKey ?? false,
                              health:           rawModel.Health?.map { .init(rawValue: $0) } ?? [],
                              magicDNSSuffix:   rawModel.MagicDNSSuffix ?? "",
                              currentTailnet:   rawModel.CurrentTailnet,
                              selfNodeID:       rawModel.Self.map { .init(rawValue: $0.ID) },
                              selfUserID:       rawModel.Self.map { .init(rawValue: $0.UserID) })
    self.tailscale = tailscale
    
    self.machines = {
      // Extract machines from dictionary and also add Self machine to list
      ((rawModel.Peer.map { Array($0.values) } ?? []) + (rawModel.Self.map { [$0] } ?? []))
      // Sort the IDs in some deterministic way
        .sorted { $0.ID < $1.ID }
      // Convert them into polished models
        .map { Machine($0, selfID: tailscale.selfNodeID) }
    }()
    
    self.users = Dictionary<User.Identifier, User>(
      uniqueKeysWithValues: rawModel.User?.map { (.init(rawValue: $0), $1) } ?? []
    )
    
    self.lookUp = Dictionary(uniqueKeysWithValues: self.machines.flatMap { machine in
      return [(machine.id, machine)] + (machine.children?.map { ($0.id, $0) } ?? [])
    })
  }
}

extension Machine {
  
  /// Init for advertised subnets
  internal init(address: Address, name: String, hostID: Machine.Identifier, selfID: Machine.Identifier?) {
    self.id   = .init(rawValue: (selfID?.rawValue ?? "INVALID") + ":" + address.rawValue)
    self.name = address.rawValue
    self.host = address.rawValue
    self.ips  = [address]
    self.kind = hostID == selfID ? .meSubnet : .remoteSubnet
    self.relay = .route(id: hostID, name: name)
  }
  
  /// Init for JSON from the Tailscale CLI
  internal init(_ model: MachineCLI, selfID: Machine.Identifier?) {
    self.id       = .init(rawValue: model.ID)
    self.name     = model.HostName ?? ""
    self.host     = model.DNSName  ?? ""
    self.ips      = model.TailscaleIPs?.map({ Address(rawValue: $0) }) ?? []
    self.os       = model.OS       ?? ""
    self.kind     = model.ID == selfID?.rawValue ? .meHost : .remoteHost
    self.relay    = .relay(model.Relay ?? "")
    self.userID   = .init(rawValue:   model.UserID)
    self.activity = .init(isExitNode: model.ExitNode ?? false,
                          isOnline:   model.Online ?? false,
                          isActive:   model.Active ?? false,
                          rxBytes:    Int64(model.RxBytes ?? 0),
                          txBytes:    Int64(model.TxBytes ?? 0),
                          lastSeen:   model.LastSeen.flatMap(df.date(from:)))
    
    self.subnetRoutes = model.PrimaryRoutes?.map { Subnet(rawValue: $0) } ?? []
    self.children     = self.subnetRoutes.flatMap { subnet in
      subnet.explodeAddresses().map { address in
        Machine(address: address,
                name:    model.HostName ?? "",
                hostID: .init(rawValue: model.ID),
                selfID:  selfID)
      }
    }
    if self.children?.isEmpty ?? false {
      // TODO: Remove when this bug is fixed in SwiftUI.Table
      // Nil this out or the table will show an arrow but will open to nothing
      self.children = nil
    }
    
    // Had to move these out of the init because the type checker was timing out
    let keyExpiry     = model.KeyExpiry    .flatMap(df.date(from:))
    let created       = model.Created      .flatMap(df.date(from:))
    let lastWrite     = model.LastWrite    .flatMap(df.date(from:))
    let lastHandshake = model.LastHandshake.flatMap(df.date(from:))
    
    self.nodeInfo = .init(
      publicKey:     model.PublicKey ?? "",
      keyExpiry:     keyExpiry,
      created:       created,
      lastWrite:     lastWrite,
      lastHandshake: lastHandshake,
      inNetworkMap:  model.InNetworkMap ?? false,
      inMagicSock:   model.InMagicSock  ?? false,
      inEngine:      model.InEngine     ?? false
    )
  }
}
