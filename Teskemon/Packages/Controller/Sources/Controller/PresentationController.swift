//
//  Created by Jeffrey Bergier on 2025/01/19.
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
public struct PresentationController: DynamicProperty {
  
  public struct Value: Codable {
    public var selection = Set<Machine.Identifier>()
    public var isShowingInfoPanel = Set<Machine.Identifier>()
    public var showsPasswords = false
  }
  
  @JSBSceneStorage("Presentation") private var storage = Value()
  
  public init() { }
  
  public var wrappedValue: Value {
    get { self.storage }
    nonmutating set { self.storage = newValue }
  }
  
  public var projectedValue: Binding<Value> {
    return self.$storage
  }
  
}
