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

nonisolated(unsafe) internal let dateFormatter = ISO8601DateFormatter()

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
      internal let version: String
      internal let tun: Bool
      internal let backendState: String
      internal let haveNodeKey: Bool
      internal let authURL: String?
      internal let tailscaleIPs: [String]?
      internal let selfNode: Node
      internal let health: [String]
      internal let magicDNSSuffix: String
      internal let currentTailnet: Tailnet?
      internal let certDomains: [String]?
      internal let peer: [String: Node]?
      internal let user: [String: User]?
      internal let clientVersion: ClientVersion?
      
      internal enum CodingKeys: String, CodingKey {
        case version = "Version"
        case tun = "TUN"
        case backendState = "BackendState"
        case haveNodeKey = "HaveNodeKey"
        case authURL = "AuthURL"
        case tailscaleIPs = "TailscaleIPs"
        case selfNode = "Self"
        case health = "Health"
        case magicDNSSuffix = "MagicDNSSuffix"
        case currentTailnet = "CurrentTailnet"
        case certDomains = "CertDomains"
        case peer = "Peer"
        case user = "User"
        case clientVersion = "ClientVersion"
      }
    }
    
    internal struct Node: Codable {
      internal let id: String
      internal let publicKey: String
      internal let hostName: String
      internal let dnsName: String
      internal let os: String
      internal let userID: Int
      internal let tailscaleIPs: [String]
      internal let allowedIPs: [String]
      internal let primaryRoutes: [String]?
      internal let addrs: [String]?
      internal let curAddr: String
      internal let relay: String
      internal let rxBytes: Int
      internal let txBytes: Int
      internal let created: String
      internal let lastWrite: String?
      internal let lastSeen: String?
      internal let lastHandshake: String?
      internal let online: Bool
      internal let exitNode: Bool
      internal let exitNodeOption: Bool
      internal let active: Bool
      internal let peerAPIURL: [String]?
      internal let capabilities: [String]?
      internal let capMap: [String: String?]?
      internal let inNetworkMap: Bool
      internal let inMagicSock: Bool
      internal let inEngine: Bool
      internal let keyExpiry: String?
      
      internal enum CodingKeys: String, CodingKey {
        case id = "ID"
        case publicKey = "PublicKey"
        case hostName = "HostName"
        case dnsName = "DNSName"
        case os = "OS"
        case userID = "UserID"
        case tailscaleIPs = "TailscaleIPs"
        case allowedIPs = "AllowedIPs"
        case primaryRoutes = "PrimaryRoutes"
        case addrs = "Addrs"
        case curAddr = "CurAddr"
        case relay = "Relay"
        case rxBytes = "RxBytes"
        case txBytes = "TxBytes"
        case created = "Created"
        case lastWrite = "LastWrite"
        case lastSeen = "LastSeen"
        case lastHandshake = "LastHandshake"
        case online = "Online"
        case exitNode = "ExitNode"
        case exitNodeOption = "ExitNodeOption"
        case active = "Active"
        case peerAPIURL = "PeerAPIURL"
        case capabilities = "Capabilities"
        case capMap = "CapMap"
        case inNetworkMap = "InNetworkMap"
        case inMagicSock = "InMagicSock"
        case inEngine = "InEngine"
        case keyExpiry = "KeyExpiry"
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
    public let currentTailnet: Tailnet
    // Nodes
    public let selfNode: Node
    public let peerNodes: [Node]
    // Users
    public let selfUser: User?
    public let peerUsers: [String:User]
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
    public let tailscaleIPs: [Subnet]
    public let subnetRoutes: [Subnet]
    public let region: String
    // Traffic
    public let rxBytes: Int
    public let txBytes: Int
    // Timestamps
    public let created: Date
    public let lastWrite: Date?
    public let lastSeen: Date?
    public let lastHandshake: Date?
    // Status
    public let isOnline: Bool
    public let isActive: Bool
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
