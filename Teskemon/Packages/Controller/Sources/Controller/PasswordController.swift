//
//  Created by Jeffrey Bergier on 2025/01/18.
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
import KeychainSwift

// TODO: Improve performance with Keychain

@MainActor
@propertyWrapper
public struct PasswordController: DynamicProperty {
  
  internal static let sharedCache = PasswordController.Value()
  
  @ObservedObject private var storage: Value
  
  public init() {
    _storage = .init(initialValue: PasswordController.sharedCache)
  }
  
  public var wrappedValue: Value {
    self.storage
  }
}

extension PasswordController {
  
  @MainActor
  public class Value: ObservableObject {
    
    public enum Namespace {
      case username
      case password
    }
    
    private enum Cache {
      case knownMissing
      case available(String)
      internal var value: String? {
        switch self {
        case .knownMissing: return nil
        case .available(let value): return value
        }
      }
    }
    
    private let usernameKeychain = KeychainSwift(keyPrefix: "teskemon/username/")
    private let passwordKeychain = KeychainSwift(keyPrefix: "teskemon/password/")
    
    private var cache: [Namespace: [Machine.Identifier: Cache]] = {
      return [
        .username: .init(),
        .password: .init()
      ]
    }()
    
    public subscript (space: Namespace, id: Machine.Identifier) -> String? {
      get {
        if let cache = self.cache[space]![id] { return cache.value }
        if let uncached = self.keychain(for: space).get(id.rawValue) {
          self.cache[space]![id] = .available(uncached)
          return uncached
        } else {
          self.cache[space]![id] = .knownMissing
          return nil
        }
      }
      set {
        self.objectWillChange.send()
        
        guard let newValue = newValue?.trimmed else {
          self.keychain(for: space).delete(id.rawValue)
          self.cache[space]![id] = .knownMissing
          return
        }
        
        self.keychain(for: space).set(newValue, forKey: id.rawValue)
        self.cache[space]![id] = .available(newValue)
      }
    }
    
    public func binding(_ space: Namespace, _ id: Machine.Identifier) -> Binding<String> {
      return Binding(get: { self[space, id] ?? "" },
                     set: { self[space, id] = $0.trimmed })
    }
    
    private func keychain(for space: Namespace) -> KeychainSwift {
      switch space {
      case .username: return self.usernameKeychain
      case .password: return self.passwordKeychain
      }
    }
  }
}
