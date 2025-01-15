//
//  Created by Jeffrey Bergier on 2025/01/12.
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

public struct MachineIdentifier: Codable, Sendable, Hashable, Identifiable, RawRepresentable {
  public var id: String { return self.rawValue }
  public let rawValue: String
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct MachineActivity: Codable, Sendable, Hashable {
  public let isOnline: Bool
  public let isActive: Bool
  public let rxBytes: Int64
  public let txBytes: Int64
  public let lastSeen: Date?
}

public enum MachineKind: Codable, Sendable, Hashable {
  case meHost, remoteHost, meSubnet, remoteSubnet
}

public protocol Machine: Codable, Sendable {
  var id: MachineIdentifier { get }
  var name: String { get }
  var url: String { get }
  var os: String? { get }
  var kind: MachineKind { get }
  var relay: Either<String, MachineIdentifier> { get }
  var activity: MachineActivity? { get }
}

public struct HostMachine: Machine, Codable, Sendable, Identifiable {
  // Machine Conformance
  public let id: MachineIdentifier
  public let name: String
  public let url: String
  public let os: String?
  public let kind: MachineKind
  public let relay: Either<String, MachineIdentifier>
  public let activity: MachineActivity?
  
  // Information
  public let publicKey: String
  public let keyExpiry: Date?
  public let isExitNode: Bool
  public let userID: Int
  
  // Network
  public let tailscaleIPs: [Address]
  public let subnetRoutes: [Subnet]
  
  // Timestamps
  public let created: Date
  public let lastWrite: Date?
  public let lastHandshake: Date?
  // Status
  public let inNetworkMap: Bool
  public let inMagicSock: Bool
  public let inEngine: Bool
}

public struct SubnetMachine: Machine, Codable, Sendable, Identifiable {
  // Machine Conformance
  public let id: MachineIdentifier
  public let name: String
  public let url: String
  public let os: String?
  public let kind: MachineKind
  public let relay: Either<String, MachineIdentifier>
  public let activity: MachineActivity?
  
  internal init(address: Address, hostID: MachineIdentifier, selfID: MachineIdentifier) {
    self.id   = .init(rawValue: selfID.rawValue + ":" + address.rawValue)
    self.name = address.rawValue
    self.url  = address.rawValue
    self.os   = nil
    self.kind = hostID == selfID ? .meSubnet : .remoteSubnet
    self.relay    = .right(hostID)
    self.activity = nil
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

public struct Service: Codable, Sendable, Hashable, Identifiable {
  
  public enum Status: Codable, Sendable, Hashable {
    case unknown
    case error
    case online
    case offline
    case processing
  }
  
  public static let `default`: [Service] = {
    return [
      Service(name: "AFP", protocol: "afp", port: 548),
      Service(name: "SSH", protocol: "ssh", port: 22),
      Service(name: "SMB", protocol: "smb", port: 445),
      Service(name: "RDP", protocol: "rdp", port: 3389),
      Service(name: "VNC", protocol: "vnc", port: 5900),
    ]
  }()
  
  public var name: String
  public var `protocol`: String
  public var port: Int
  public var id: Int { self.port }
}

public struct Tailscale: Codable, Sendable {
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
  // Identification
  public let selfNodeID: MachineIdentifier
  public let selfUserID: User.Identifier
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
