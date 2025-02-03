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

@MainActor
@propertyWrapper
public struct PasswordController: DynamicProperty {
  
  @MainActor
  internal class Cache: ObservableObject {
    
    private var cache: [Machine.Identifier: Password] = [:]
    @Published internal var passwords: [Machine.Identifier: Password] = [:]
    
    internal subscript(machine: Machine) -> Password {
      set {
        self.passwords[machine.id] = newValue
      }
      get {
        if let password = self.passwords[machine.id] { return password }
        if let password = self.cache[machine.id]     { return password }
        let password = PasswordController.query(machine)
        self.cache[machine.id] = password
        return password
      }
    }
  }
  
  @MainActor
  public struct Value {
    internal var cache: Cache
    public subscript(machine: Machine) -> Password {
      get { self.cache[machine] }
      nonmutating set { self.cache[machine] = newValue }
    }
    
    public func bind(machine: Machine) -> Binding<Password> {
      return Binding {
        return self.cache[machine]
      } set: {
        self.cache[machine] = $0
      }
    }
  }
  
  @MachineController  private var machines
  @StateObject private var cache = Cache()
  
  public var wrappedValue: Value {
    .init(cache: self.cache)
  }
  
  public init() { }
  
  public func delete(id: Machine.Identifier) {
    
  }
  
  // TODO: Make async throwing
  public func save(machine: Machine) -> Password.Status {
    let password = self.wrappedValue[machine]
    
    let status: OSStatus
    switch password.status {
    case .newModified:
      switch password.valueForSaving {
      case .success(let toSave):
        status = SecItemAdd(toSave as CFDictionary, nil)
      case .failure(let error):
        return .error(error)
      }
    case .savedModified:
      switch password.valueForUpdates {
      case .success(let toUpdate):
        status = SecItemUpdate(password.valueForUpdating as CFDictionary,
                               toUpdate as CFDictionary)
      case .failure(let error):
        return .error(error)
      }
    case .new, .saved, .keychainError, .error:
      fatalError("Tried to save password that is not in the modified state")
    }
    
    guard status == errSecSuccess else {
      return .keychainError(status)
    }
    
    return .saved
  }
  
  internal static func query(_ machine: Machine) -> Password {
    // Create Query
    let rawQuery: [CFString: Any] = [
      kSecClass:            Password.defaultClass,
      kSecAttrCreator:      Password.defaultCreator,
      kSecMatchLimit:       kSecMatchLimitOne,
      kSecReturnData:       true,
      kSecReturnAttributes: true,
      kSecAttrServer:       machine.url,
    ]
    
    // Perform Query
    var item: CFTypeRef?
    let status: OSStatus = SecItemCopyMatching(rawQuery as CFDictionary, &item)
    return Password(secItemCopyStatus: status, payload: item, machine: machine)
  }
}
