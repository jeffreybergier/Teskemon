//
//  Created by Jeffrey Bergier on 2025/01/14.
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

public struct Address: Codable, Sendable, RawRepresentable {
  public let rawValue: String
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct Subnet: Codable, Sendable, RawRepresentable {
  public let rawValue: String
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension Subnet {
  // Copied and pasted from ChatGPT. Sorry, no better source
  internal func explodeAddresses() -> [Address] {
    let components = self.rawValue.split(separator: "/")
    guard
      components.count == 2,
      let baseIP = components.first,
      let prefixLength = Int(components.last!),
      prefixLength >= 0 && prefixLength <= 32
    else { return [] }
    
    // Convert base IP to an integer
    let ipParts = baseIP.split(separator: ".").compactMap { UInt32($0) }
    guard ipParts.count == 4 else { return [] }
    
    let baseIPInt = (ipParts[0] << 24) | (ipParts[1] << 16) | (ipParts[2] << 8) | ipParts[3]
    
    // Calculate the range of IPs
    let hostBits = 32 - prefixLength
    let numberOfIPs = 1 << hostBits
    let startIP = baseIPInt & ~UInt32(numberOfIPs - 1)
    let endIP = startIP + UInt32(numberOfIPs) - 1
    
    // Generate IPs
    var ipList:[Address] = []
    for ip in startIP...endIP {
      let part1 = (ip >> 24) & 0xFF
      let part2 = (ip >> 16) & 0xFF
      let part3 = (ip >> 8)  & 0xFF
      let part4 = ip & 0xFF
      ipList.append(.init(rawValue: "\(part1).\(part2).\(part3).\(part4)"))
    }
    
    return ipList
  }
}
