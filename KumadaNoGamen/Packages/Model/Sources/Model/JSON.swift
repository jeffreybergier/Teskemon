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
    var machines = Dictionary<MachineIdentifier, Machine>(
      uniqueKeysWithValues: model.Peer?.map { (.init(rawValue: $1.ID), $1.clean()) } ?? []
    )
    machines[.init(rawValue: model.Self.ID)] = model.Self.clean()
    let something = machines[.init(rawValue: "nYed447uzA21CNTRL")]!.subnetRoutes.map {
        $0.explodeAddresses()
    }
    self.tailscale = tailscale
    self.machineIDs = Array(machines.keys.sorted(by: { $0.rawValue > $1.rawValue }))
    self.machines = machines
    self.users = users
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
    
    internal func clean() -> Machine {
      return .init(id: .init(rawValue: self.ID),
                   publicKey: self.PublicKey,
                   keyExpiry: self.KeyExpiry.flatMap(df.date(from:)),
                   name: self.HostName,
                   url: self.DNSName,
                   os: self.OS,
                   userID: self.UserID,
                   isExitNode: self.ExitNode,
                   tailscaleIPs: self.TailscaleIPs.map { Address(rawValue: $0) },
                   subnetRoutes: self.PrimaryRoutes?.map { Subnet(rawValue: $0) } ?? [],
                   region: self.Relay,
                   isActive: self.Active,
                   rxBytes: Int64(self.RxBytes),
                   txBytes: Int64(self.TxBytes),
                   created: df.date(from: self.Created)!,
                   lastWrite: self.LastWrite.flatMap(df.date(from:)),
                   lastSeen: self.LastSeen.flatMap(df.date(from:)),
                   lastHandshake: self.LastHandshake.flatMap(df.date(from:)),
                   isOnline: self.Online,
                   inNetworkMap: self.InNetworkMap,
                   inMagicSock: self.InMagicSock,
                   inEngine: self.InEngine)
    }
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
