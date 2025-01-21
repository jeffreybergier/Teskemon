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

public struct Machine: Codable, Sendable, Identifiable {
  
  // Machine Conformance
  public let id: Identifier
  public let name: String
  public let url: String
  public let os: String?
  public let kind: Kind
  public let relay: Relay
  public let activity: Activity?
  public let subnetRoutes: [Machine]?
  public let nodeInfo: NodeInfo?
  
  /// Init for advertised subnets
  internal init(address: Address, hostName: String, hostID: Machine.Identifier, selfID: Machine.Identifier?) {
    self.id   = .init(rawValue: (selfID?.rawValue ?? "INVALID") + ":" + address.rawValue)
    self.name = address.rawValue
    self.url  = address.rawValue
    self.os   = nil
    self.kind = hostID == selfID ? .meSubnet : .remoteSubnet
    self.relay = .route(id: hostID, name: hostName)
    self.activity = nil
    self.subnetRoutes = nil
    self.nodeInfo = nil
  }
  
  /// Init for JSON from the Tailscale CLI
  internal init(_ model: JSON.MachineCLI, selfID: Machine.Identifier?) {
    self.id       = .init(rawValue: model.ID)
    self.name     = model.HostName
    self.url      = model.DNSName
    self.os       = model.OS
    self.kind     = model.ID == (selfID?.rawValue ?? "INVALID") ? .meHost : .remoteHost
    self.relay    = .relay(model.Relay)
    self.activity = .init(isOnline: model.Online,
                          isActive: model.Active,
                          rxBytes: Int64(model.RxBytes),
                          txBytes: Int64(model.TxBytes),
                          lastSeen: model.LastSeen.flatMap(df.date(from:)))
    
    let subnetRoutes: [Machine]? = model.PrimaryRoutes?.flatMap { subnet in
      Subnet(rawValue: subnet).explodeAddresses().map { address in
        Machine(address: address,
                hostName: model.HostName,
                hostID: .init(rawValue: model.ID),
                selfID: selfID)
      }
    }
    self.subnetRoutes = (subnetRoutes?.isEmpty ?? true) ? nil : subnetRoutes
    
    self.nodeInfo = .init(
      publicKey: model.PublicKey,
      keyExpiry: model.KeyExpiry.flatMap(df.date(from:)),
      isExitNode: model.ExitNode,
      userID: model.UserID,
      tailscaleIPs: model.TailscaleIPs.map { Address(rawValue: $0) },
      created: df.date(from: model.Created)!,
      lastWrite: model.LastWrite.flatMap(df.date(from:)),
      lastHandshake: model.LastWrite.flatMap(df.date(from:)),
      inNetworkMap: model.InNetworkMap,
      inMagicSock: model.InMagicSock,
      inEngine: model.InEngine
    )
  }
}

extension Machine {
  public struct Identifier: Identifiable, Codable, Sendable, Hashable, RawRepresentable {
    public var id: String { return self.rawValue }
    public let rawValue: String
    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }
  
  public struct Activity: Codable, Sendable, Hashable {
    public let isOnline: Bool
    public let isActive: Bool
    public let rxBytes: Int64
    public let txBytes: Int64
    public let lastSeen: Date?
  }
  
  public enum Kind: Codable, Sendable, Hashable {
    case meHost, remoteHost, meSubnet, remoteSubnet
  }
  
  public enum Relay: Codable, Sendable, Hashable {
    case relay(String)
    case route(id: Machine.Identifier, name: String)
    public var displayName: String {
      switch self {
      case .relay(let name): return name
      case .route(_, let name): return name
      }
    }
  }
  
  public struct NodeInfo: Codable, Sendable, Hashable {
    // Information
    public let publicKey: String
    public let keyExpiry: Date?
    public let isExitNode: Bool
    public let userID: Int
    
    // Network
    public let tailscaleIPs: [Address]
    
    // Timestamps
    public let created: Date
    public let lastWrite: Date?
    public let lastHandshake: Date?
    // Status
    public let inNetworkMap: Bool
    public let inMagicSock: Bool
    public let inEngine: Bool
  }
}

public struct User: Codable, Sendable {
  public struct Identifier: Codable, Sendable, Hashable, Identifiable, RawRepresentable {
    public var id: Int { return self.rawValue }
    public let rawValue: Int
    public init(rawValue: Int) {
      self.rawValue = rawValue
    }
  }
  public let id: Identifier
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

public struct Tailscale: Codable, Sendable {
  // Status
  public let version: String
  public let versionUpToDate: Bool
  public let tunnelingEnabled: Bool
  public let backendState: String
  public let haveNodeKey: Bool
  public let health: [HealthEntry]
  // Network
  public let magicDNSSuffix: String
  public let currentTailnet: Tailnet?
  // Identification
  public let selfNodeID: Machine.Identifier?
  public let selfUserID: User.Identifier?
}

public struct Tailnet: Codable, Sendable {
  public let name: String
  public let magicDNSSuffix: String
  public let magicDNSEnabled: Bool
  
  public enum CodingKeys: String, CodingKey {
    case name = "Name"
    case magicDNSSuffix = "MagicDNSSuffix"
    case magicDNSEnabled = "MagicDNSEnabled"
  }
}

public struct HealthEntry: Codable, RawRepresentable, Identifiable, Sendable, Hashable {
  public var rawValue: String
  public var id: String { self.rawValue }
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}
