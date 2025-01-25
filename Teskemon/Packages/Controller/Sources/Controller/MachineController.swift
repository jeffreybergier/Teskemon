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
public struct MachineController: DynamicProperty {
  
  public typealias Value = Machine.ControllerValue
  
  @JSBSceneStorage("Table") private var storage = Value()

  public init() {}
  
  public var wrappedValue: Value {
    get { self.storage }
    nonmutating set { self.storage = newValue }
  }
  
  public var projectedValue: Binding<Value> {
    self.$storage
  }
  
  public func resetData() {
    self.storage.tailscale = nil
    self.storage.machines = []
    self.storage.users = [:]
    // TODO: Figure out why clearing the cache here crashes it
  }
  
  public func updateMachines(with executable: SettingsExecutable) async throws {
    guard self.storage.isLoading == false else { return }
    NSLog("[START] TableController.updateMachines()")
    self.storage.isLoading = true
    do {
      self.storage = try await Process.machines(with: executable.stringValue)
      self.storage.isLoading = false
      NSLog("[END  ] TableController.updateMachines()")
    } catch {
      self.storage.isLoading = false
      NSLog("[ERROR] TableController.updateMachines()")
      throw error
    }
  }
}


