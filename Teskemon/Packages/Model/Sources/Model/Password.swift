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
  
  public static let creator = OSType(string: "SATM")
  
  public enum Status: Sendable, Equatable, Hashable {
    case new
    case newModified
    case saved
    case savedModified
    case error(OSStatus)
  }
  
  public var status:      Status = .new
  public var account:     String = ""
  public var path:        String = ""
  public var port:        String = ""
  public var `protocol`:  String = ""
  public var server:      String = ""
  public var description: String = ""
  public var comment:     String = ""
  public var label:       String = ""
  public var password:    String = ""
  public var `class`:     String = kSecClassInternetPassword as String
  public var creator:     OSType = Password.creator
  public var accessGroup: String = Bundle.main.bundleIdentifier!
  
  public init() {}
}

extension Password {
  public struct Query {
    public var id: Machine.Identifier
    public var server: String
    public var `class`: String = kSecClassInternetPassword as String
    public var creator: OSType = OSType(string: "SATM")
    public var accessGroup: String = Bundle.main.bundleIdentifier!
    public init(id: Machine.Identifier, server: String) {
      self.id = id
      self.server = server
    }
  }
}

extension OSStatus {
  public var description: String {
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
