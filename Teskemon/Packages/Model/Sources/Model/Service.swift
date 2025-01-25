//
//  Created by Jeffrey Bergier on 2025/01/18.
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

public struct Service: Codable, Sendable, Hashable, Identifiable {
  
  public enum Status: Codable, Sendable {
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
  public var id: Int = Int.random(in: 0...10_000)
  
  public init(name: String = "", protocol: String = "", port: Int = 0) {
    self.name = name
    self.protocol = `protocol`
    self.port = port
  }
}

extension Service {
  public struct ControllerValue: Codable {
    internal var status: [Machine.Identifier: [Service: Service.Status]] = [:]
    public var isLoading = false
    public subscript(id: Machine.Identifier, service: Service) -> Service.Status {
      get { self.status[id, default: [:]][service] ?? .unknown }
      set { self.status[id, default: [:]][service] = newValue }
    }
    public enum CodingKeys: String, CodingKey {
      case status
    }
    public init() {}
  }
}
