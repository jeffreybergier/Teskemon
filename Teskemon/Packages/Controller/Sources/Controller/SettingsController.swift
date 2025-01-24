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

import SwiftUI
import Umbrella
import Model

@MainActor
@propertyWrapper
public struct SettingsController: DynamicProperty {
  
  // TODO: Move this to model
  public struct Value: Codable {
    public var currentTab: Tab = .general
    public var services = Service.default
    public var timeout = 10
    public var batchSize = 10
    public var executable = Executable()
    public var customNames = [Machine.Identifier: String]()
    public var statusTimer = Timer(automatic: false, interval: 300)
    public var machineTimer = Timer(automatic: true, interval: 10)
    
    public mutating func delete(service: Service) {
      guard let index = self.services.firstIndex(where: { $0.id == service.id }) else { return }
      self.services.remove(at: index)
    }
  }
  
  public enum Tab: Codable {
    case general
    case services
  }
  
  public struct Timer: Codable {
    public var automatic: Bool
    public var interval: Int
  }
  
  public struct Executable: Codable {
    
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
  
  @JSBAppStorage("Settings") private var model = Value()
  
  public init() { }
  
  public var wrappedValue: Value {
    get { self.model }
    nonmutating set { self.model = newValue }
  }
  
  public var projectedValue: Binding<Value> {
    return self.$model
  }
  
}
