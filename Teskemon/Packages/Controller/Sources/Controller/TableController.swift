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

import SwiftUI
import Model
import Umbrella

@MainActor
@propertyWrapper
public struct TableController: DynamicProperty {
  
  internal class Cache: ObservableObject {
    internal var cache: [Machine.Identifier: Machine] = [:]
    internal func fetch(id: Machine.Identifier, onMiss: () -> Machine) -> Machine {
      if let cachedValue = self.cache[id] { return cachedValue }
      // TODO: Spend more time troubleshooting cache misses
      // They should only happen on fresh start
      // but are happening on reset as well
      let missedValue = onMiss()
      self.cache[id] = missedValue
      return missedValue
    }
    internal func reset(_ newValue: [Machine.Identifier: Machine] = [:]) {
      self.cache = newValue
    }
  }
  
  public struct Value {
    
    public let tailscale: Tailscale?
    public let machines: [Machine]
    public let users: [Machine.Identifier: User]
    internal var cache: Cache
    
    public func url(for service: Service,
                    on id: Machine.Identifier,
                    username: String?,
                    password:String?) -> URL
    {
      if let username, let password {
        // TODO: Switch to using NSURLComponent
        return URL(string: "\(service.protocol)://\(username):\(password)@\(self.machine(for: id).url):\(service.port)")!
      } else {
        return URL(string: "\(service.protocol)://\(self.machine(for: id).url):\(service.port)")!
      }
    }
    
    public func machines(for selection: Set<Machine.Identifier>) -> [Machine] {
      let selectedMachines = selection.map { self.machine(for: $0) }
      if !selectedMachines.isEmpty { return selectedMachines }
      return self.machines.flatMap {
        return [$0] + ($0.subnetRoutes ?? [])
      }
    }
    
    public func machine(for id: Machine.Identifier) -> Machine {
      return self.cache.fetch(id: id) { [machines] in
        for parent in machines {
          if parent.id == id { return parent }
          for child in parent.subnetRoutes ?? [] {
            if child.id == id {
              return child
            }
          }
        }
        fatalError()
      }
    }
  }
  
  @PresentationController private var presentation
  
  @JSBSceneStorage("Controller.Tailscale") private var tailscale: Tailscale? = nil
  @JSBSceneStorage("Controller.Machines")  private var machines = [Machine]()
  @JSBSceneStorage("Controller.Users")     private var users    = [Machine.Identifier: User]()
  
  @StateObject private var cache = Cache()
  
  public init() {}
  
  public var wrappedValue: Value {
    .init(tailscale: self.tailscale,
          machines:  self.machines,
          users:     self.users,
          cache:     self.cache)
  }
  
  public func resetData() {
    self.tailscale = nil
    self.machines  = []
    self.users     = [:]
    self.cache.reset()
  }
  
  public func updateMachines(with executable: SettingsController.Executable) async throws {
    NSLog("[START] TableController.updateMachines()")
    let output = try await Process.cliOutput(with: executable.stringValue)
    self.tailscale = output.tailscale
    self.machines  = output.machines
    self.users     = output.users
    self.cache.reset(output.lookUpCache)
    NSLog("[END  ] TableController.updateMachines()")
  }
}


