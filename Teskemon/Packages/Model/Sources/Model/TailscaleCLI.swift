//
//  Created by Jeffrey Bergier on 2025/01/15.
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

internal struct TailscaleCLI: Codable, Sendable {
  internal var Version:        String?
  internal var TUN:            Bool?
  internal var BackendState:   String?
  internal var HaveNodeKey:    Bool?
  internal var AuthURL:        String?
  internal var TailscaleIPs:  [String]?
  internal var Health:        [String]?
  internal var MagicDNSSuffix: String?
  internal var CertDomains:   [String]?
  internal var Peer:  [String: MachineCLI]?
  internal var User:     [Int: User]?
  internal var `Self`:         MachineCLI?
  internal var CurrentTailnet: Tailnet?
  internal var ClientVersion:  ClientVersion?
}

internal struct MachineCLI: Codable, Sendable {
  internal var ID:             String
  internal var UserID:         Int
  internal var PublicKey:      String?
  internal var HostName:       String?
  internal var DNSName:        String?
  internal var OS:             String?
  internal var TailscaleIPs:  [String]?
  internal var AllowedIPs:    [String]?
  internal var PrimaryRoutes: [String]?
  internal var Addrs:         [String]?
  internal var CurAddr:        String?
  internal var Relay:          String?
  internal var RxBytes:        Int?
  internal var TxBytes:        Int?
  internal var Created:        String?
  internal var LastWrite:      String?
  internal var LastSeen:       String?
  internal var LastHandshake:  String?
  internal var Online:         Bool?
  internal var ExitNode:       Bool?
  internal var ExitNodeOption: Bool?
  internal var Active:         Bool?
  internal var PeerAPIURL:    [String]?
  internal var Capabilities:  [String]?
  internal var CapMap: [String:String?]?
  internal var InNetworkMap:   Bool?
  internal var InMagicSock:    Bool?
  internal var InEngine:       Bool?
  internal var KeyExpiry:      String?
}

internal struct ClientVersion: Codable, Sendable {
  internal let runningLatest: Bool?
  internal enum CodingKeys: String, CodingKey {
    case runningLatest = "RunningLatest"
  }
}

nonisolated(unsafe) internal let df: ISO8601DateFormatter = {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  return formatter
}()
