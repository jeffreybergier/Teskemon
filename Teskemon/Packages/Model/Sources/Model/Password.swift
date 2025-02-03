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

public struct Password: Sendable, Equatable, Hashable {
  
  public static let defaultCreator     = OSType(string: "SATM")
  public static let defaultDescription = "Teskemon password"
  public static let defaultClass       = kSecClassInternetPassword as String
  
  // TODO: This is not needed, just use the machine
  public struct Query {
    public var machine: Machine
    public var `class`: String = Password.defaultClass
    public var creator: OSType = Password.defaultCreator
    public init(machine: Machine) {
      self.machine = machine
    }
  }
  
  public enum Error: Swift.Error, Sendable, Equatable, Hashable {
    case missingUsernameOrPassword
    case machineDataIncorrect
    case criticalDataIncorrect
  }
  
  public enum Status: Sendable, Equatable, Hashable {
    case new
    case newModified
    case saved
    case savedModified
    case keychainError(OSStatus)
    case error(Error)
  }
  
  public var status: Status = .new
  
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

extension Password {
}

extension OSStatus {
  public var localizedDescription: String {
    String(SecCopyErrorMessageString(self, nil)!)
  }
}

// https://github.com/lvsti/Cutis/blob/master/Cutis/OSType.swift

extension OSType {
  public init(string: String) {
    self.init(UTGetOSTypeFromString(string as CFString))
  }
  public var stringValue: String {
    return .init(osType: self)
  }
}

extension String {
  public init(osType: OSType) {
    let str = UTCreateStringForOSType(osType).takeRetainedValue()
    self.init(str as NSString)
  }
}
