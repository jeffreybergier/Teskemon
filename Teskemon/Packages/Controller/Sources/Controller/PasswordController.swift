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
  
  public struct Value: Sendable, Equatable, Hashable {
    public var passwords: [Machine.Identifier: Password] = [:]
    public subscript(id: Machine.Identifier) -> Password {
      get { self.passwords[id, default: .init()] }
      set { self.passwords[id] = newValue }
    }
  }
  
  @MachineController  private var machines
  @State private var values: Value = .init()
  
  public var wrappedValue: Value {
    get { self.values }
    nonmutating set { self.values = newValue }
  }
  
  public var projectedValue: Binding<Value> {
    self.$values
  }
  
  public init() { }
  
  public func prefetch(ids: [Machine.Identifier]) {
    for id in ids {
      self.values[id] = self.fetch(id: id)
    }
  }
  
  public func delete(id: Machine.Identifier) {
    
  }
  
  // TODO: Make async throwing
  public func save(id: Machine.Identifier) -> Password.Status {
    let password = self.values[id]
    
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
  
  private func fetch(id: Machine.Identifier) -> Password {
    return type(of: self).query(self.machines[id])
  }
  
  private static func query(_ machine: Machine) -> Password {
    // Create Query
    let rawQuery: [CFString: Any] = [
      kSecClass:            Password.defaultClass,
      kSecAttrCreator:      Password.defaultCreator,
      kSecMatchLimit:       kSecMatchLimitOne,
      kSecReturnAttributes: true,
      kSecReturnData:       true,
      kSecAttrServer:       machine.url,
    ]
    
    // Perform Query
    var item: CFTypeRef?
    let status: OSStatus = SecItemCopyMatching(rawQuery as CFDictionary, &item)
    return Password(secItemCopyStatus: status, payload: item, machine: machine)
  }
}
