//
//  Created by Jeffrey Bergier on 2025/01/18.
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
