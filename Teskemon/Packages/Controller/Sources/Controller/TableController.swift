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
  
  public typealias Value = TailscaleCLIOutput
  
  @JSBSceneStorage("Table") private var table = TailscaleCLIOutput()

  public init() {}
  
  public var wrappedValue: Value {
    get { self.table }
    nonmutating set { self.table = newValue }
  }
  
  public var projectedValue: Binding<Value> {
    self.$table
  }
  
  public func resetData() {
    self.table.tailscale = nil
    self.table.machines = []
    self.table.users = [:]
    // TODO: Figure out why clearing the cache here crashes it
  }
  
  public func updateMachines(with executable: SettingsController.Executable) async throws {
    NSLog("[START] TableController.updateMachines()")
    self.table.isLoading = true
    self.table = try await Process.cliOutput(with: executable.stringValue)
    NSLog("[END  ] TableController.updateMachines()")
  }
}


