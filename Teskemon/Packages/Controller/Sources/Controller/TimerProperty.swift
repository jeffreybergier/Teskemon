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
  
  public struct Key: Hashable {
    public let identifier: String
    public let interval: TimeInterval
  }
  
  public struct Value: Equatable {
    
    /// Set to less than 0.1 to pause timer
    public var interval:    TimeInterval
    public let identifier:  String
    public var fireCount:   Int = 0
    
    public var isRunning: Bool {
      return self.interval >= 0.1
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
  
  /// Set interval to less than 0.1 to pause timer
  public init(identifier: String, interval: TimeInterval = 0) {
    let key = Key(identifier: identifier, interval: interval)
    let timer: TimerBox
    if let existingTimer = TimerProperty.timers[key] {
      timer = existingTimer
    } else {
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
  
  private var configurationChanged = false
  @Published internal var value: TimerProperty.Value {
    willSet {
      self.configurationChanged = self.value.interval != newValue.interval
    }
    didSet {
      // Check if the configuration changed
      guard self.configurationChanged else { return }
      // Ensure the timer is supposed to run or else cancel it
      guard self.value.isRunning else {
        self.timer?.invalidate()
        self.timer = nil
        return
      }
      
      // Create a closure to configure the timer if needed
      let configureTimer = { [self] in
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: self.value.interval,
                                          target: self,
                                          selector: #selector(timerFired(_:)),
                                          userInfo: nil,
                                          repeats: true)
      }
      // If the timer is not set, create it
      guard let timer else {
        configureTimer()
        return
      }
      // If the time interval doesn't match, recreate the timer
      guard timer.timeInterval == self.value.interval else {
        configureTimer()
        return
      }
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
