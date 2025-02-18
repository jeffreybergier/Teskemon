//
//  Created by Jeffrey Bergier on 2025/02/01.
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

extension CFString: @unchecked @retroactive Sendable {}

public struct Password: Sendable, Equatable, Hashable {
  
  public static let defaultCreator     = OSType(string: "SATM")
  public static let defaultDescription = "Teskemon password"
  public static let defaultClass       = kSecClassInternetPassword as String
  
  public typealias Descriptor = [CFString: any Sendable]
  
  public enum Error: Swift.Error, Sendable, Equatable, Hashable {
    public var errorCode: Int {
      switch self {
      case .missingUsernameOrPassword: return -1
      case .machineDataIncorrect:      return -2
      case .criticalDataIncorrect:     return -3
      case .keychain(let status):      return Int(status)
      }
    }
    case missingUsernameOrPassword
    case machineDataIncorrect
    case criticalDataIncorrect
    case keychain(OSStatus)
  }
  
  public enum Status: Sendable, Equatable, Hashable {
    case isEditing
    case isViewing
    case error(Error)
  }
  
  public var status: Status = .isViewing
  public var inKeychain = false
  
  // Editable by the user in the app
  public var user_account:  String = ""
  public var user_password: String = ""
  
  // Set by the app but are specific to each keychain entry
  public var app_server: String = ""
  public var app_label:  String = ""
  
  // Set but are constant across all keychain entries
  public var const_class:       String = Password.defaultClass
  public var const_creator:     OSType = Password.defaultCreator
  public var const_description: String = Password.defaultDescription
  
  // So far ununsed by the app
  public var unused_path:     String = ""
  public var unused_port:     String = ""
  public var unused_protocol: String = ""
  public var unused_comment:  String = ""
  
  public init() {}
}

// MARK: Keychain Support

extension Password {
  public init(from descriptor: Descriptor) {
    self.inKeychain = true
    
    // Configured by the user
    self.user_account  = descriptor[kSecAttrAccount] as! String
    self.user_password = String(data: descriptor[kSecValueData] as! Data, encoding: .utf8)!
    
    // Configured by app
    self.app_label  = descriptor[kSecAttrLabel ] as! String
    self.app_server = descriptor[kSecAttrServer] as! String
    
    // Constant across all keychain entries
    self.const_class       = descriptor[kSecClass          ] as! String
    self.const_creator     = descriptor[kSecAttrCreator    ] as! OSType
    self.const_description = descriptor[kSecAttrDescription] as! String
    
    // So far, unused by the app
    self.unused_path     = descriptor[kSecAttrPath    ] as? String ?? ""
    self.unused_port     = descriptor[kSecAttrPort    ] as? String ?? ""
    self.unused_comment  = descriptor[kSecAttrComment ] as? String ?? ""
    self.unused_protocol = descriptor[kSecAttrProtocol] as? String ?? ""
    
    // Validate what was read from keychain
    guard
      self.const_description == Password.defaultDescription,
      self.const_creator     == Password.defaultCreator,
      self.const_class       == Password.defaultClass
    else {
      self.status = .error(.criticalDataIncorrect)
      return
    }
    
    // Validate what was read from keychain
    guard self.user_account.trimmed != nil, self.user_password.trimmed != nil else {
      self.status = .error(.missingUsernameOrPassword)
      return
    }
  }
  
  public func valueForUpdating() -> Descriptor {
    var query: Descriptor = [
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
  
  public func valueForUpdate() throws(Password.Error) -> Descriptor {
    guard
      let accountString = self.user_account.trimmed,
      let passwordData  = self.user_password.data(using: .utf8)
    else {
      throw .missingUsernameOrPassword
    }
    
    return [
      kSecAttrAccount: accountString,
      kSecValueData:   passwordData
    ]
  }
  
  public func valueForSaving() throws(Password.Error) -> Descriptor {
    guard
      let accountString = self.user_account.trimmed,
      let passwordData  = self.user_password.trimmed?.data(using: .utf8),
      passwordData.isEmpty == false
    else {
      throw .missingUsernameOrPassword
    }
    
    var query = self.valueForUpdating()
    query[kSecAttrAccount] = accountString
    query[kSecValueData  ] = passwordData
    
    return query
  }
}

extension OSStatus {
  public var secErrorMessage: String {
    String(SecCopyErrorMessageString(self, nil)!)
  }
}

// https://github.com/lvsti/Cutis/blob/master/Cutis/OSType.swift

extension OSType {
  public init(string: String) {
    self.init(UTGetOSTypeFromString(string as CFString))
  }
  /*
  public var stringValue: String {
    let str = UTCreateStringForOSType(self).takeRetainedValue() as NSString
    return str as String
  }
  */
}
