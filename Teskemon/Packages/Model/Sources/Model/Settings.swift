//
//  Created by Jeffrey Bergier on 2025/01/25.
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

public struct SettingsControllerValue: Codable {
  
  public var currentTab   = SettingsTab.tailscale
  public var services     = Service.default
  public var scanning     = Scanning()
  public var customNames  = [Machine.Identifier: String]()
  public var executable   = SettingsExecutable()
  public var statusTimer  = SettingsTimer(automatic: false, interval: 300)
  public var machineTimer = SettingsTimer(automatic: true, interval: 60)
  
  public mutating func delete(service: Service) {
    guard let index = self.services.firstIndex(where: { $0.id == service.id }) else { return }
    self.services.remove(at: index)
  }
  
  public init() {}
}

public enum SettingsTab: Codable {
  case tailscale
  case services
  case scanning
}

public struct SettingsTimer: Codable, Equatable {
  public var automatic: Bool
  public var interval: TimeInterval
}

public struct SettingsExecutable: Codable {
  
  public enum Options: CaseIterable, Codable {
    case cli
    case app
    case custom
  }
  
  public var option: Options = .cli
  public var rawValue = ""
  public var stringValue: String {
    switch self.option {
    case .cli:    return "/usr/local/bin/tailscale"
    case .app:    return "/Applications/Tailscale.app/Contents/MacOS/Tailscale"
    case .custom: return self.rawValue
    }
  }
}

public struct Scanning: Codable, Sendable {
  public var batchSize:     Int    = 10
  public var pingCount:     Int    = 10
  public var netcatTimeout: Int    = 10
  public var pingLoss:      Double = 30
}
