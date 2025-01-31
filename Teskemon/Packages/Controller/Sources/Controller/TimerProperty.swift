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


// TODO: Improve the performance of timer
// Make a slow one for updating the services
// Make a fast one that disables when the app is not foreground

@MainActor
@propertyWrapper
public struct TimerProperty: DynamicProperty {
  
  public struct Key: Hashable {
    public let identifier: String
    public let interval: TimeInterval
  }
  
  public struct Value: Equatable {
    
    public               let identifier: String
    public internal(set) var fireCount: Int = 0
    public               var interval: TimeInterval
    private              var retainCount: UInt = 0
    
    public mutating func retain() {
      self.retainCount += 1
    }
    public mutating func release() {
      guard self.retainCount > 0 else { return }
      self.retainCount -= 1
    }
    public var isRunning: Bool {
      self.retainCount > 0
    }
    
    internal init(identifier: String, interval: TimeInterval) {
      self.identifier = identifier
      self.interval = interval
    }
    
    public func numerator(for denominator: Int) -> Double {
      return Double(1*(self.fireCount % denominator))
    }
    
    public func percentage(of denominator: Int) -> Double {
      return self.numerator(for: denominator) / Double(denominator)
    }
  }
  
  private static var timers = [Key: TimerBox]()
  
  @ObservedObject private var timer: TimerBox
  
  public init(identifier: String, interval: TimeInterval) {
    let key = Key(identifier: identifier, interval: interval)
    var timer: TimerBox! = TimerProperty.timers[key]
    if timer == nil {
      timer = TimerBox(key: key)
      TimerProperty.timers[key] = timer
    }
    _timer = .init(wrappedValue: timer)
  }
  
  public var wrappedValue: Value {
    get {
      return self.timer.value
    }
    nonmutating set {
      self.timer.value = newValue
    }
  }
}

fileprivate class TimerBox: ObservableObject {
  
  @Published internal var value: TimerProperty.Value {
    didSet {
      guard self.value.isRunning else {
        self.timer?.invalidate()
        self.timer = nil
        return
      }
      let configureTimer = { [self] in
        self.timer = Timer.scheduledTimer(timeInterval: self.value.interval,
                                          target: self,
                                          selector: #selector(timerFired(_:)),
                                          userInfo: nil,
                                          repeats: true)
      }
      guard let timer else { configureTimer(); return }
      guard timer.timeInterval == self.value.interval else { configureTimer(); return }
    }
  }
  
  internal var timer: Timer?
  
  @objc private func timerFired(_ timer: Timer) {
    self.value.fireCount += 1
  }
  
  internal init(key: TimerProperty.Key) {
    self.value = TimerProperty.Value(identifier: key.identifier, interval: key.interval)
  }
}
