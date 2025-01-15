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

extension TableModel {
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
    let users = Dictionary<MachineIdentifier, User>(
      uniqueKeysWithValues: model.User?.map { (.init(rawValue: $0), $1) } ?? []
    )
    
    var ids: [MachineIdentifier] = []
    var hosts: [MachineIdentifier: HostMachine] = [:]
    var subnets: [MachineIdentifier: SubnetMachine] = [:]
    
    let modelMachines = [model.Self] + (model.Peer.map { Array($0.values) } ?? [])
    for modelMachine in modelMachines {
      let machine = HostMachine(modelMachine, meID: tailscale.selfNodeID)
      ids.append(machine.id)
      hosts[machine.id] = machine
      for subnet in machine.subnetRoutes {
        for address in subnet.explodeAddresses() {
          let subnetMachine = SubnetMachine(address: address,
                                            hostID: machine.id,
                                            selfID: tailscale.selfNodeID)
          ids.append(subnetMachine.id)
          subnets[subnetMachine.id] = subnetMachine
        }
      }
    }
    
    self.tailscale = tailscale
    self.ids = ids
    self.hosts = hosts
    self.subnets = subnets
    self.users = users
  }
}

extension HostMachine {
  internal init(_ model: JSON.MachineCLI, meID: MachineIdentifier) {
    self.id       = .init(rawValue: model.ID)
    self.name     = model.HostName
    self.url      = model.DNSName
    self.os       = model.OS
    self.kind     = model.ID == meID.rawValue ? .meHost : .remoteHost
    self.relay    = .left(model.Relay)
    self.activity = .init(isOnline: model.Online,
                         isActive: model.Active,
                         rxBytes: Int64(model.RxBytes),
                         txBytes: Int64(model.TxBytes),
                         lastSeen: model.LastSeen.flatMap(df.date(from:)))
    self.publicKey     = model.PublicKey
    self.keyExpiry     = model.KeyExpiry.flatMap(df.date(from:))
    self.isExitNode    = model.ExitNode
    self.userID        = model.UserID
    self.tailscaleIPs  = model.TailscaleIPs.map { Address(rawValue: $0) }
    self.subnetRoutes  = model.PrimaryRoutes?.map { Subnet(rawValue: $0) } ?? []
    self.created       = df.date(from: model.Created)!
    self.lastWrite     = model.LastWrite.flatMap(df.date(from:))
    self.lastHandshake = model.LastHandshake.flatMap(df.date(from:))
    self.inNetworkMap  = model.InNetworkMap
    self.inMagicSock   = model.InMagicSock
    self.inEngine      = model.InEngine
  }
}

internal enum JSON {
  
  internal struct TailscaleCLI: Codable, Sendable {
    internal let Version: String
    internal let TUN: Bool
    internal let BackendState: String
    internal let HaveNodeKey: Bool
    internal let AuthURL: String?
    internal let TailscaleIPs: [String]?
    internal let `Self`: MachineCLI
    internal let Health: [String]
    internal let MagicDNSSuffix: String
    internal let CurrentTailnet: Tailnet?
    internal let CertDomains: [String]?
    internal let Peer: [String: MachineCLI]?
    internal let User: [String: User]?
    internal let ClientVersion: ClientVersion?
  }
  
  internal struct MachineCLI: Codable, Sendable {
    internal let ID: String
    internal let PublicKey: String
    internal let HostName: String
    internal let DNSName: String
    internal let OS: String
    internal let UserID: Int
    internal let TailscaleIPs: [String]
    internal let AllowedIPs: [String]
    internal let PrimaryRoutes: [String]?
    internal let Addrs: [String]?
    internal let CurAddr: String
    internal let Relay: String
    internal let RxBytes: Int
    internal let TxBytes: Int
    internal let Created: String
    internal let LastWrite: String?
    internal let LastSeen: String?
    internal let LastHandshake: String?
    internal let Online: Bool
    internal let ExitNode: Bool
    internal let ExitNodeOption: Bool
    internal let Active: Bool
    internal let PeerAPIURL: [String]?
    internal let Capabilities: [String]?
    internal let CapMap: [String: String?]?
    internal let InNetworkMap: Bool
    internal let InMagicSock: Bool
    internal let InEngine: Bool
    internal let KeyExpiry: String?
  }
  
  internal struct ClientVersion: Codable, Sendable {
    internal let runningLatest: Bool
    internal enum CodingKeys: String, CodingKey {
      case runningLatest = "RunningLatest"
    }
  }
}

nonisolated(unsafe) internal let df: ISO8601DateFormatter = {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  return formatter
}()
