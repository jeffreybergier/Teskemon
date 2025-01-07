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

@Model
final class Item {
  var timestamp: Date
  
  init(timestamp: Date) {
    self.timestamp = timestamp
  }
}

public struct TailscaleStatus: Codable {
  public let version: String
  public let tun: Bool
  public let backendState: String
  public let haveNodeKey: Bool
  public let authURL: String?
  public let tailscaleIPs: [String]
  public let selfNode: Node
  public let health: [String]
  public let magicDNSSuffix: String
  public let currentTailnet: Tailnet?
  public let certDomains: [String]?
  public let peer: [String: Node]?
  public let user: [String: User]?
  public let clientVersion: ClientVersion?
  
  public enum CodingKeys: String, CodingKey {
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

// Node structure for `Self` and `Peer`
public struct Node: Codable {
  public let id: String
  public let publicKey: String
  public let hostName: String
  public let dnsName: String
  public let os: String
  public let userID: Int
  public let tailscaleIPs: [String]
  public let allowedIPs: [String]
  public let addrs: [String]?
  public let curAddr: String
  public let relay: String
  public let rxBytes: Int
  public let txBytes: Int
  public let created: String
  public let lastWrite: String?
  public let lastSeen: String?
  public let lastHandshake: String?
  public let online: Bool
  public let exitNode: Bool
  public let exitNodeOption: Bool
  public let active: Bool
  public let peerAPIURL: [String]
  public let capabilities: [String]?
  public let capMap: [String: String?]?
  public let inNetworkMap: Bool
  public let inMagicSock: Bool
  public let inEngine: Bool
  public let keyExpiry: String?
  
  public enum CodingKeys: String, CodingKey {
    case id = "ID"
    case publicKey = "PublicKey"
    case hostName = "HostName"
    case dnsName = "DNSName"
    case os = "OS"
    case userID = "UserID"
    case tailscaleIPs = "TailscaleIPs"
    case allowedIPs = "AllowedIPs"
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

// Tailnet structure
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

// User structure
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

// ClientVersion structure
public struct ClientVersion: Codable {
  public let runningLatest: Bool
  
  public enum CodingKeys: String, CodingKey {
    case runningLatest = "RunningLatest"
  }
}
