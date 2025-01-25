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
  
  @JSBSceneStorage("Status") private var status = Value()
  
  public init() { }
  
  public var wrappedValue: Value {
    get { self.status }
    nonmutating set { self.status = newValue }
  }
  
  public var projectedValue: Binding<Value> {
    return self.$status
  }
  
  public func updateStatus(for services: [Service],
                           on machines: [Machine],
                           timeout: Int,
                           batchSize: Int) async throws
  {
    guard self.status.isLoading == false else { return }
    NSLog("[START] StatusController.updateStatus()")
    self.status.isLoading = true
    do {
      try await Process.serviceStatus(for: services,
                                      on: machines,
                                      bind: self.$status,
                                      timeout: timeout,
                                      batchSize: batchSize)
      self.status.isLoading = false
      NSLog("[END  ] StatusController.updateStatus()")
    } catch {
      self.status.isLoading = false
      NSLog("[ERROR] StatusController.updateStatus()")
      throw error
    }
  }
  
  public func resetData() {
    self.status = Value()
  }
}
