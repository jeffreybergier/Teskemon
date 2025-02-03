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
  public func save(id: Machine.Identifier) {
    let password = self.values[id]
    guard password.user_account.trimmed != nil, password.user_password.trimmed != nil else { return }
    let status: OSStatus
    switch password.status {
    case .newModified:
      status = SecItemAdd(password.valueForSaving as CFDictionary, nil)
    case .savedModified:
      status = SecItemUpdate(password.valueForQuery    as CFDictionary,
                             password.valueForUpdating as CFDictionary)
    case .new, .saved, .error:
      return
    }
    
    // TODO: Create custom error here
    guard status == errSecSuccess else {
      print(status.description)
      return
    }
    
    self.values[id].status = .saved
  }
  
  // TODO: Make Async
  private func fetch(id: Machine.Identifier) -> Password {
    let machine = self.machines[id]
    let query = Password.Query(machine: machine)
    let password = type(of: self).query(query)
    return password
  }
  
  // TODO: Make Async
  private static func query(_ query: Password.Query) -> Password {
    var output = Password()
    
    // Create Query
    let rawQuery: [CFString: Any] = [
      kSecClass:            query.class,
      kSecAttrServer:       query.machine.url,
      kSecAttrCreator:      query.creator,
      kSecMatchLimit:       kSecMatchLimitOne,
      kSecReturnAttributes: true,
      kSecReturnData:       true,
    ]
    
    // Perform Query
    var item: CFTypeRef?
    let status: OSStatus = SecItemCopyMatching(rawQuery as CFDictionary, &item)
    switch status {
    case errSecItemNotFound:
      output.status = .new
      output.app_server = query.machine.url
      output.app_label  = "\(query.machine.url) (\(query.machine.name)<\(query.machine.id.rawValue)>)"
    case errSecSuccess:
      output.status = .saved
    default:
      output.status = .error(status)
    }
    
    // Parse results
    guard let rawPassword = item as? [CFString: Any] else { return output }
    
    // TODO: Do more validation here and return errors for malformed passwords

    // Configured by the user
    output.user_account  = rawPassword[kSecAttrAccount] as! String
    output.user_password = String(data: rawPassword[kSecValueData] as! Data, encoding: .utf8)!
    
    // Configured by app
    output.app_server      = rawPassword[kSecAttrServer] as! String
    output.app_label       = rawPassword[kSecAttrLabel ] as! String
    
    // Constant across all keychain entries
    output.const_description = rawPassword[kSecAttrDescription] as! String
    output.const_creator     = rawPassword[kSecAttrCreator    ] as! OSType
    output.const_class       = rawPassword[kSecClass]           as! String
    
    // So far, unused by the app
    output.unused_path     = rawPassword[kSecAttrPath    ] as? String ?? ""
    output.unused_port     = rawPassword[kSecAttrPort    ] as? String ?? ""
    output.unused_protocol = rawPassword[kSecAttrProtocol] as? String ?? ""
    output.unused_comment  = rawPassword[kSecAttrComment ] as? String ?? ""
    
    guard output.const_description == Password.defaultDescription,
          output.const_creator == Password.defaultCreator,
          output.const_class == Password.defaultClass
    else {
      // TODO: Make my own errors
      output.status = .error(5)
      assertionFailure()
      return output
    }
    
    return output
  }
}

extension Password {
  internal var valueForQuery: [CFString: Any] {
    var query: [CFString : Any] = [
      kSecClass:           self.const_class,
      kSecAttrCreator:     self.const_creator,
      kSecAttrDescription: self.const_description,
      kSecAttrServer:      self.app_server,
      kSecAttrLabel:       self.app_label,
    ]
    
    query[kSecAttrComment ] = self.unused_comment.trimmed
    query[kSecAttrProtocol] = self.unused_protocol.trimmed
    query[kSecAttrPath    ] = self.unused_path.trimmed
    query[kSecAttrPort    ] = self.unused_port.trimmed
    
    return query
  }
  
  // TODO: Make throwing or return result to show bad username and password
  internal var valueForSaving: [CFString: Any] {
    var query = self.valueForQuery
    query[kSecAttrAccount] = self.user_account.trimmed
    query[kSecValueData  ] = self.user_password.data(using: .utf8)!
    return query
  }
  
  // TODO: Make throwing or return result to show bad username and password
  internal var valueForUpdating: [CFString: Any] {
    return [
      kSecAttrAccount: self.user_account,
      kSecValueData:   self.user_password.data(using: .utf8)!
    ]
  }
}
