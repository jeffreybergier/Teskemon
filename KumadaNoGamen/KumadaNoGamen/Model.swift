//
//  Created by Jeffrey Bergier on 15/1/18.
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
//  along with WaterMe.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import SwiftData

nonisolated(unsafe) internal let df: ISO8601DateFormatter = {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  return formatter
}()

@Model
final class Item {
  var timestamp: Date
  
  init(timestamp: Date) {
    self.timestamp = timestamp
  }
}

public enum Tailscale {
  internal enum Raw {
    internal struct Status: Codable {
      internal let Version: String
      internal let TUN: Bool
      internal let BackendState: String
      internal let HaveNodeKey: Bool
      internal let AuthURL: String?
      internal let TailscaleIPs: [String]?
      internal let `Self`: Node
      internal let Health: [String]
      internal let MagicDNSSuffix: String
      internal let CurrentTailnet: Tailnet?
      internal let CertDomains: [String]?
      internal let Peer: [String: Node]?
      internal let User: [String: User]?
      internal let ClientVersion: ClientVersion?
      
      internal func clean() -> Tailscale.Status {
        let peers: [Tailscale.Node] = self.Peer?.values.map { $0.clean() } ?? []
        let users: [String: Tailscale.User] = self.User ?? [:]
        return .init(version: self.Version,
                     versionUpToDate: self.ClientVersion?.runningLatest ?? false,
                     tunnelingEnabled: self.TUN,
                     backendState: self.BackendState,
                     haveNodeKey: self.HaveNodeKey,
                     health: self.Health,
                     magicDNSSuffix: self.MagicDNSSuffix,
                     currentTailnet: self.CurrentTailnet,
                     selfNode: self.Self.clean(),
                     peerNodes: peers,
                     users: users)
      }
  
    }
    
    internal struct Node: Codable {
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
      
      internal func clean() -> Tailscale.Node {
        return .init(id: self.ID,
                     publicKey: self.PublicKey,
                     keyExpiry: self.KeyExpiry.flatMap(df.date(from:)),
                     hostName: self.HostName,
                     dnsName: self.DNSName,
                     os: self.OS,
                     userID: self.UserID,
                     isExitNode: self.ExitNode,
                     tailscaleIPs: self.TailscaleIPs.map { Tailscale.Address(rawValue: $0) },
                     subnetRoutes: self.PrimaryRoutes?.map { Tailscale.Subnet(rawValue: $0) } ?? [],
                     region: self.Relay,
                     isActive: self.Active,
                     rxBytes: self.RxBytes,
                     txBytes: self.TxBytes,
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
    
    internal struct ClientVersion: Codable {
      internal let runningLatest: Bool
      internal enum CodingKeys: String, CodingKey {
        case runningLatest = "RunningLatest"
      }
    }
  }
  
  public struct Status: Codable {
    // Status
    public let version: String
    public let versionUpToDate: Bool
    public let tunnelingEnabled: Bool
    public let backendState: String
    public let haveNodeKey: Bool
    public let health: [String]
    // Network
    public let magicDNSSuffix: String
    public let currentTailnet: Tailnet?
    // Nodes
    public let selfNode: Node
    public let peerNodes: [Node]
    // Users
    public let users: [String: User]
  }
  
  public struct Node: Codable {
    // Information
    public let id: String
    public let publicKey: String
    public let keyExpiry: Date?
    public let hostName: String
    public let dnsName: String
    public let os: String
    public let userID: Int
    public let isExitNode: Bool
    // Network
    public let tailscaleIPs: [Address]
    public let subnetRoutes: [Subnet]
    public let region: String
    // Traffic
    public let isActive: Bool
    public let rxBytes: Int
    public let txBytes: Int
    // Timestamps
    public let created: Date
    public let lastWrite: Date?
    public let lastSeen: Date?
    public let lastHandshake: Date?
    // Status
    public let isOnline: Bool
    public let inNetworkMap: Bool
    public let inMagicSock: Bool
    public let inEngine: Bool
  }
  
  public struct Tailnet: Codable {
    public let name: String
    public let magicDNSSuffix: String
    public let magicDNSEnabled: Bool
    
    public enum CodingKeys: String, CodingKey {
      case name = "Name"
      case magicDNSSuffix = "MagicDNSSuffix"
      case magicDNSEnabled = "MagicDNSEnabled"
    }
  }
  
  public struct Subnet: Codable, RawRepresentable {
    public let rawValue: String
    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }
  
  public struct Address: Codable, RawRepresentable {
    public let rawValue: String
    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }

  public struct User: Codable {
    public let id: Int
    public let loginName: String
    public let displayName: String
    public let profilePicURL: String
    public let roles: [String]
    
    public enum CodingKeys: String, CodingKey {
      case id = "ID"
      case loginName = "LoginName"
      case displayName = "DisplayName"
      case profilePicURL = "ProfilePicURL"
      case roles = "Roles"
    }
  }
}
