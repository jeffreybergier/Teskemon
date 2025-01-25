//
//  Created by Jeffrey Bergier on 2025/01/21.
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
public struct ServiceController: DynamicProperty {
  
  public typealias Value = Service.ControllerValue
  
  @JSBSceneStorage("Status") private var storage = Value()
  
  public init() { }
  
  public var wrappedValue: Value {
    get { self.storage }
    nonmutating set { self.storage = newValue }
  }
  
  public var projectedValue: Binding<Value> {
    return self.$storage
  }
  
  public func updateStatus(for services: [Service],
                           on machines: [Machine],
                           timeout: Int,
                           batchSize: Int) async throws
  {
    guard self.storage.isLoading == false else { return }
    let onCompletion: () -> Void = {
      self.storage.progress.totalUnitCount = 0
      self.storage.progress.completedUnitCount = 0
    }
    
    NSLog("[START] StatusController.updateStatus()")
    onCompletion()
    do {
      try await Process.allStatus(services: services,
                                  machines: machines,
                                  netcatTimeout: timeout,
                                  pingCount: 12,
                                  pingLossThreshold: 30,
                                  batchSize: batchSize,
                                  bind: self.$storage)
      onCompletion()
      NSLog("[END  ] StatusController.updateStatus()")
    } catch {
      onCompletion()
      NSLog("[ERROR] StatusController.updateStatus()")
      throw error
    }
  }
  
  public func resetData() {
    self.storage = Value()
  }
}
