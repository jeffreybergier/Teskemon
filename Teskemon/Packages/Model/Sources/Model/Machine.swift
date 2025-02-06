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

extension Machine {
  public struct ControllerValue: Codable {
    
    public   var isLoading: Bool = false
    public   var tailscale: Tailscale?
    public   var machines:  [Machine]
    public   var users:     [Machine.Identifier: User]
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
        return ((rawModel.Peer.map { Array($0.values) } ?? [])
                + (rawModel.Self.map { [$0] } ?? []))      // Extract machines from dictionary and also add Self machine to list
        .sorted { $0.ID < $1.ID }                          // Sort the IDs in some deterministic way
        .map { Machine($0, selfID: tailscale.selfNodeID) } // Conver them into polished models
      }()
      self.users = Dictionary<Machine.Identifier, User>(
        uniqueKeysWithValues: rawModel.User?.map { (.init(rawValue: $0), $1) } ?? []
      )
      self.lookUp = Dictionary(uniqueKeysWithValues: self.machines.flatMap { machine in
        return [(machine.id, machine)] + (machine.subnetRoutes?.map { ($0.id, $0) } ?? [])
      })
    }
  }
  
  public func url(for service: Service,
                  username: String?,
                  password: String?) -> URL?
  {
    var components      = URLComponents()
    components.host     = self.host
    components.user     = username
    components.password = password
    if service.port > 0 {
      components.port   = service.port
    }
    if !service.scheme.isEmpty {
      components.scheme = service.scheme
    }
    return components.url
  }
}

public struct Machine: Codable, Sendable, Identifiable {
  
  public var id: Identifier = .init(rawValue: "")
  public var name: String   = ""
  public var host: String   = ""
  public var os: String     = ""
  public var kind: Kind     = .remoteSubnet
  public var relay: Relay   = .relay("")
  public var activity: Activity  = .init()
  public var nodeInfo: NodeInfo? = nil
  public var subnetRoutes: [Machine]? = nil
  
  internal init() {}
  
  /// Init for advertised subnets
  internal init(address: Address, name: String, hostID: Machine.Identifier, selfID: Machine.Identifier?) {
    self.id   = .init(rawValue: (selfID?.rawValue ?? "INVALID") + ":" + address.rawValue)
    self.name = address.rawValue
    self.host = address.rawValue
    self.kind = hostID == selfID ? .meSubnet : .remoteSubnet
    self.relay = .route(id: hostID, name: name)
  }
  
  /// Init for JSON from the Tailscale CLI
  internal init(_ model: MachineCLI, selfID: Machine.Identifier?) {
    self.id       = .init(rawValue: model.ID)
    self.name     = model.HostName ?? ""
    self.host     = model.DNSName  ?? ""
    self.os       = model.OS       ?? ""
    self.kind     = model.ID == selfID?.rawValue ? .meHost : .remoteHost
    self.relay    = .relay(model.Relay ?? "")
    self.activity = .init(isOnline: model.Online ?? false,
                          isActive: model.Active ?? false,
                          rxBytes:  Int64(model.RxBytes ?? 0),
                          txBytes:  Int64(model.TxBytes ?? 0),
                          lastSeen: model.LastSeen.flatMap(df.date(from:)))
    
    let subnetRoutes: [Machine]? = model.PrimaryRoutes?.flatMap { subnet in
      Subnet(rawValue: subnet).explodeAddresses().map { address in
        Machine(address: address,
                name:    model.HostName ?? "",
                hostID: .init(rawValue: model.ID),
                selfID:  selfID)
      }
    }
    self.subnetRoutes = (subnetRoutes?.isEmpty ?? true) ? nil : subnetRoutes
    
    // Had to move these out of the init because the type checker was timing out
    let keyExpiry     = model.KeyExpiry.flatMap(df.date(from:))
    let tailscaleIPs  = model.TailscaleIPs?.map({ Address(rawValue: $0) }) ?? []
    let created       = model.Created.flatMap(df.date(from:))
    let lastWrite     = model.LastWrite.flatMap(df.date(from:))
    let lastHandshake = model.LastWrite.flatMap(df.date(from:))
    
    self.nodeInfo = .init(
      publicKey:     model.PublicKey ?? "",
      keyExpiry:     keyExpiry,
      isExitNode:    model.ExitNode ?? false,
      userID:        model.UserID,
      tailscaleIPs:  tailscaleIPs,
      created:       created,
      lastWrite:     lastWrite,
      lastHandshake: lastHandshake,
      inNetworkMap:  model.InNetworkMap ?? false,
      inMagicSock:   model.InMagicSock  ?? false,
      inEngine:      model.InEngine     ?? false
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
  
  public struct Activity: Codable, Sendable, Equatable {
    public var isOnline: Bool = false
    public var isActive: Bool = false
    public var rxBytes: Int64 = 0
    public var txBytes: Int64 = 0
    public var lastSeen: Date? = nil
  }
  
  public enum Kind: Codable, Sendable {
    case meHost, remoteHost, meSubnet, remoteSubnet
  }
  
  public enum Relay: Codable, Sendable {
    case relay(String)
    case route(id: Machine.Identifier, name: String)
    public var displayName: String {
      switch self {
      case .relay(let name): return name
      case .route(_, let name): return name
      }
    }
  }
  
  public struct NodeInfo: Codable, Sendable {
    // Information
    public var publicKey:  String = ""
    public var keyExpiry:  Date?  = nil
    public var isExitNode: Bool   = false
    public var userID:     Int    = -1
    
    // Network
    public var tailscaleIPs: [Address] = []
    
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
