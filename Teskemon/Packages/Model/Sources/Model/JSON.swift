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

public struct TailscaleCLIOutput: Sendable {
  
  public var tailscale:   Tailscale?
  public var machines:    [Machine]
  public var users:       [Machine.Identifier: User]
  public var lookUpCache: [Machine.Identifier: Machine]
  
  public init(data: Data) throws {
    let rawModel = try JSONDecoder().decode(JSON.TailscaleCLI.self, from: data)
    
    let tailscale = Tailscale(version: rawModel.Version,
                              versionUpToDate: rawModel.ClientVersion?.runningLatest ?? false,
                              tunnelingEnabled: rawModel.TUN,
                              backendState: rawModel.BackendState,
                              haveNodeKey: rawModel.HaveNodeKey,
                              health: rawModel.Health,
                              magicDNSSuffix: rawModel.MagicDNSSuffix,
                              currentTailnet: rawModel.CurrentTailnet,
                              selfNodeID: rawModel.Self.map { .init(rawValue: $0.ID) },
                              selfUserID: rawModel.Self.map { .init(rawValue: $0.UserID) })
    self.tailscale = tailscale
    
    self.machines = {
      return ((rawModel.Peer.map { Array($0.values) } ?? [])
              + (rawModel.Self.map { [$0] } ?? []))              // Extract machines from dictionary and also add Self machine to list
              .sorted { $0.ID < $1.ID }                          // Sort the IDs in some deterministic way
              .map { Machine($0, selfID: tailscale.selfNodeID) } // Conver them into polished models
    }()
    
    self.users = Dictionary<Machine.Identifier, User>(
      uniqueKeysWithValues: rawModel.User?.map { (.init(rawValue: $0), $1) } ?? []
    )
    
    self.lookUpCache = Dictionary(uniqueKeysWithValues: self.machines.flatMap { machine in
      return [(machine.id, machine)] + (machine.subnetRoutes?.map { ($0.id, $0) } ?? [])
    })
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
    internal let `Self`: MachineCLI?
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
