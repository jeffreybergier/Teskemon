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

@MainActor
@propertyWrapper
public struct PasswordController: DynamicProperty {
  
  public struct Value: Sendable, Equatable, Hashable {
    public var passwords: [Machine.Identifier: Password] = [:]
    public subscript(id: Machine.Identifier) -> Password {
      get { self.passwords[id, default: .init()] }
      set {
        print("set: account:`\(newValue.account)` pass:`\(newValue.password)`")
        self.passwords[id] = newValue
      }
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
  
  public func save(id: Machine.Identifier) {
    let password = self.values[id]
    guard password.account.trimmed != nil, password.password.trimmed != nil else { return }
    let status: OSStatus
    switch password.status {
    case .newModified:
      status = SecItemAdd(password.valueForSaving as CFDictionary, nil)
    case .savedModified:
      status = SecItemUpdate(password.queryValue as CFDictionary,
                             password.valueForUpdating as CFDictionary)
    case .new, .saved, .error:
      return
    }
    
    guard status == errSecSuccess else {
      print(status.description)
      return
    }
    
    self.values[id].status = .saved
  }
  
  private func fetch(id: Machine.Identifier) -> Password {
    let machine = self.machines[id]
    let query = Password.Query(id: machine.id, server: machine.url)
    let password = type(of: self).query(query)
    return password
  }
  
  public static func query(_ query: Password.Query) -> Password {
    var output = Password()
    
    // Create Query
    let rawQuery: [CFString: Any] = [
      kSecClass:            query.class       as CFString,
      kSecAttrAccessGroup:  query.accessGroup as CFString,
      kSecAttrServer:       query.server      as CFString,
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
      output.server = query.server
      output.description = query.id.rawValue
    case errSecSuccess:
      output.status = .saved
    default:
      output.status = .error(status)
    }
    
    // Parse results
    guard let rawPassword = item as? [CFString: Any] else { return output }
    output.account     = rawPassword[kSecAttrAccount    ] as? String ?? ""
    output.path        = rawPassword[kSecAttrPath       ] as? String ?? ""
    output.port        = rawPassword[kSecAttrPort       ] as? String ?? ""
    output.protocol    = rawPassword[kSecAttrProtocol   ] as? String ?? ""
    output.server      = rawPassword[kSecAttrServer     ] as? String ?? ""
    output.description = rawPassword[kSecAttrDescription] as? String ?? ""
    output.comment     = rawPassword[kSecAttrComment    ] as? String ?? ""
    output.label       = rawPassword[kSecAttrLabel      ] as? String ?? ""
    output.creator     = rawPassword[kSecAttrCreator    ] as? OSType
    output.accessGroup = rawPassword[kSecAttrAccessGroup] as? String ?? ""
    output.class       = query.class
    let passwordString = (rawPassword[kSecValueData] as? Data)
                         .map { String(data: $0, encoding: .utf8) } ?? ""
    output.password    = passwordString ?? ""
    
    guard output.description == query.id.rawValue, output.server == query.server else {
      output.status = .new
      return output
    }
    
    return output
  }
}

extension Password {
  internal var queryValue: [CFString: Any] {
    var query: [CFString : Any] = [
      kSecClass:            self.class       as CFString,
      kSecAttrAccessGroup:  self.accessGroup as CFString,
      kSecAttrServer:       self.server      as CFString,
    ]
    
    query[kSecAttrPath]        = self.path.trimmed
    query[kSecAttrPort]        = self.port.trimmed
    query[kSecAttrProtocol]    = self.protocol.trimmed
    query[kSecAttrServer]      = self.server.trimmed
    query[kSecAttrDescription] = self.description.trimmed
    query[kSecAttrComment]     = self.comment.trimmed
    query[kSecAttrLabel]       = self.label.trimmed
    query[kSecAttrCreator]     = self.creator
    query[kSecAttrAccessGroup] = self.accessGroup
    
    return query
  }
  
  internal var valueForSaving: [CFString: Any] {
    var query = self.queryValue
    query[kSecAttrAccount] = self.account.trimmed
    query[kSecValueData  ] = self.password.data(using: .utf8)!
    return query
  }
  
  internal var valueForUpdating: [CFString: Any] {
    return [
      kSecAttrAccount: self.account,
      kSecValueData:   self.password.data(using: .utf8)!
    ]
  }
}
