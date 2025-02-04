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
  public class Value: ObservableObject {
    
    internal var cache: [Machine.Identifier: Password] = [:]
    
    public subscript(machine: Machine) -> Password {
      set {
        self.objectWillChange.send()
        self.cache[machine.id] = newValue
      }
      get {
        if let password = self.cache[machine.id] { return password }
        let password = PasswordController.query(machine)
        self.cache[machine.id] = password
        return password
      }
    }
    
    public func bind(_ machine: Machine) -> Binding<Password> {
      return Binding {
        return self[machine]
      } set: {
        self[machine] = $0
      }
    }
  }
    
  @StateObject private var storage = Value()
  
  public var wrappedValue: Value {
    self.storage
  }
  
  public init() { }
  
  public func delete(id: Machine.Identifier) {
    
  }
  
  // TODO: Make async throwing
  public func save(machine: Machine) {
    var password = self.wrappedValue[machine]
    
    do {
      switch password.inKeychain {
      case false:
        let toSave = try password.valueForSaving()
        try Password.keychainAdd(item: toSave)
      case true:
        let item = password.valueForUpdating()
        let newValues = try password.valueForUpdate()
        try Password.keychainUpdate(item: item, newValues: newValues)
      }
      password.inKeychain = true
      password.status = .isViewing
      return
    } catch let error as Password.Error {
      password.status = .error(error)
      return
    } catch let error as OSStatus {
      password.status = .keychainError(error)
      return
    } catch {
      fatalError(String(describing: error))
    }
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

extension Password {
  internal static func keychainAdd(item: Descriptor) throws(OSStatus) {
    let status = SecItemAdd(item as CFDictionary, nil)
    guard status == errSecSuccess else { throw status }
    return
  }
  
  internal static func keychainUpdate(item:      Descriptor,
                                      newValues: Descriptor) throws(OSStatus)
  {
    let status = SecItemUpdate(item      as CFDictionary,
                               newValues as CFDictionary)
    guard status == errSecSuccess else { throw status }
    return
  }
}
