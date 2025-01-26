//
//  Created by Jeffrey Bergier on 2025/01/24.
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

@MainActor
@propertyWrapper
public struct TimerProperty: DynamicProperty {
  
  internal class Object: ObservableObject {
    @Published internal var value = Value(rawValue: 0)
    internal var timer: Timer?
    internal init() {
      self.timer = Timer.scheduledTimer(timeInterval: 1,
                                        target: self,
                                        selector: #selector(timerFired(_:)),
                                        userInfo: nil,
                                        repeats: true)
    }
    @objc private func timerFired(_ timer: Timer) {
      self.value.rawValue += 1
    }
  }
  
  public struct Value: RawRepresentable, Identifiable, Equatable {
    public var rawValue: Int
    public var id: Int { self.rawValue }
    public init(rawValue: Int) {
      self.rawValue = rawValue
    }
    public func hasElapsed(seconds: Int) -> Bool {
      return self.rawValue % seconds == 0
    }
    public func numerator(for denominator: Int) -> Double {
      return Double(1*(self.rawValue % denominator))
    }
    public func percentage(of denominator: Int) -> Double {
      return self.numerator(for: denominator) / Double(denominator)
    }
  }
  
  internal static let sharedTimer = Object()
  
  @ObservedObject private var storage = TimerProperty.sharedTimer
  
  public init() {}
  
  public var wrappedValue: Value {
    return self.storage.value
  }
}
