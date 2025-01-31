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
    
  internal class Object: ObservableObject {
    
    @Published internal var value: Value {
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
    
    internal init(key: Key, isRunning: Bool) {
      self.value = Value(identifier: key.identifier, interval: key.interval, isRunning: isRunning)
      guard isRunning else { return }
      self.timer = Timer.scheduledTimer(timeInterval: key.interval,
                                        target: self,
                                        selector: #selector(timerFired(_:)),
                                        userInfo: nil,
                                        repeats: true)
    }
  }
  
  public struct Key: Hashable {
    public let identifier: String
    public let interval: TimeInterval
  }
  
  public struct Value: Equatable {
    
    public let identifier: String
    public var fireCount: Int = 0
    public var interval: TimeInterval
    // TODO: Change to runningRetain count
    // to allow for += 1 -=1 for async tasks
    public var isRunning: Bool
    
    internal init(identifier: String, interval: TimeInterval, isRunning: Bool) {
      self.identifier = identifier
      self.interval = interval
      self.isRunning = isRunning
    }
    
    public func numerator(for denominator: Int) -> Double {
      return Double(1*(self.fireCount % denominator))
    }
    
    public func percentage(of denominator: Int) -> Double {
      return self.numerator(for: denominator) / Double(denominator)
    }
  }
  
  private static var timers = [Key: Object]()
  
  @ObservedObject private var timer: Object
  
  public init(identifier: String, interval: TimeInterval, isRunning: Bool = true) {
    let key = Key(identifier: identifier, interval: interval)
    var timer: Object! = TimerProperty.timers[key]
    if timer == nil {
      timer = Object(key: key, isRunning: isRunning)
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
