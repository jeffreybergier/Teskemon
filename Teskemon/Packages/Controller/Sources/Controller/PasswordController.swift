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
  
  @MainActor
  public struct Value {
    
    internal let usernames: KeychainSwift
    internal let passwords: KeychainSwift

    public func username(for id: Machine.Identifier) -> Binding<String> {
      return .init { [usernames] in
        return usernames.get(id.rawValue) ?? ""
      } set: { [usernames] in
        if let newValue = $0.trimmed {
          usernames.set(newValue, forKey: id.rawValue)
        } else {
          usernames.delete(id.rawValue)
        }
      }
    }
    public func password(for id: Machine.Identifier) -> Binding<String> {
      return .init { [passwords] in
        return passwords.get(id.rawValue) ?? ""
      } set: { [passwords] in
        if let newValue = $0.trimmed {
          passwords.set(newValue, forKey: id.rawValue)
        } else {
          passwords.delete(id.rawValue)
        }
      }
    }
  }
  
  @StateObject private var usernames = ObserveBox(KeychainSwift(keyPrefix: "TeskeMon.Username."))
  @StateObject private var passwords = ObserveBox(KeychainSwift(keyPrefix: "TeskeMon.Password."))
  
  public init() { }
  
  public var wrappedValue: Value {
    .init(usernames: self.usernames.value,
          passwords: self.passwords.value)
  }
}
