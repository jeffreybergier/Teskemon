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
  
  public var id:       Identifier = .init(rawValue: "")
  public var name:     String     = ""
  public var host:     String     = ""
  public var ips:      [Address]  = []
  public var os:       String     = ""
  public var kind:     Kind       = .unknown
  public var relay:    Relay      = .unknown
  public var userID:   User.Identifier = .init(rawValue: -1)
  public var activity: Activity?    = nil
  public var nodeInfo: NodeInfo?    = nil
  public var children: [Machine]?   = nil
  public var subnetRoutes: [Subnet] = []
  
  public func url(for service: Service,
                  username: String?,
                  password: String?) -> URL?
  {
    var components  = URLComponents()
    components.host = self.host
    if service.usesUsername {
      components.user = username
    }
    if service.usesPassword {
      components.password = password
    }
    if service.port > 0 {
      components.port = service.port
    }
    if !service.scheme.isEmpty {
      components.scheme = service.scheme
    }
    return components.url
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
  
  public struct Activity: Codable, Sendable, Equatable {
    public var isExitNode: Bool = false
    public var isOnline: Bool   = false
    public var isActive: Bool   = false
    public var rxBytes: Int64   = 0
    public var txBytes: Int64   = 0
    public var lastSeen: Date?  = nil
  }
  
  public enum Kind: Codable, Sendable {
    case unknown, meHost, remoteHost, meSubnet, remoteSubnet
  }
  
  public enum Relay: Codable, Sendable {
    case unknown
    case relay(String)
    case route(id: Machine.Identifier, name: String)
    public var displayName: String {
      switch self {
      case .unknown:            return "–"
      case .relay(let name):    return name
      case .route(_, let name): return name
      }
    }
  }
  
  public struct NodeInfo: Codable, Sendable {
    // Information
    public var publicKey:  String = ""
    public var keyExpiry:  Date?  = nil
    
    // Network
    
    // Timestamps
    public var created:       Date? = nil
    public var lastWrite:     Date? = nil
    public var lastHandshake: Date? = nil
    // Status
    public var inNetworkMap: Bool = false
    public var inMagicSock:  Bool = false
    public var inEngine:     Bool = false
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
  
  // TODO: Consider fixing the Codable so ths string is automatically handled
  public var profilePicURLValue: URL? {
    URL(string: profilePicURL)
  }
  
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

public struct HealthEntry: Codable, RawRepresentable, Identifiable, Sendable {
  public var rawValue: String
  public var id: String { self.rawValue }
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}
