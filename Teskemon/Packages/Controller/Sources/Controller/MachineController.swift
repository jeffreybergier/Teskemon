//
//  Created by Jeffrey Bergier on 2025/01/12.
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
import Model
import Umbrella

@MainActor
@propertyWrapper
public struct MachineController: DynamicProperty {
  
  public typealias Value = MachineModel
  
  @JSBSceneStorage("Table") private var storage = Value()

  public init() {}
  
  public var wrappedValue: Value {
    get { self.storage }
    nonmutating set { self.storage = newValue }
  }
  
  public var projectedValue: Binding<Value> {
    self.$storage
  }
  
  public func resetData() {
    self.storage = .init()
  }
  
  public func updateMachines(with executable: SettingsModel.Executable) async throws {
    guard self.storage.isLoading == false else { return }
    NSLog("[START] TableController.updateMachines()")
    self.storage.isLoading = true
    do {
      self.storage = try await Process.machines(with: executable.stringValue)
      self.storage.isLoading = false
      NSLog("[END  ] TableController.updateMachines()")
    } catch {
      self.storage.isLoading = false
      NSLog("[ERROR] TableController.updateMachines()")
      NSLog(String(describing: error))
      throw error
    }
  }
}

extension Machine {
  public func url(for service: Service,
                  username: String,
                  password: String) -> URL?
  {
    // First check if the custom URL for RDP can make a URL
    if let url = self.rdp_url(for: service, username: username, password: password) {
      return url
    }
    
    // Otherwise just do the normal
    return self.fallback_url(for: service, username: username, password: password)
  }
  
  internal func rdp_url(for service: Service,
                        username: String,
                        password: String) -> URL?
  {
    guard service.scheme.lowercased() == "rdp" else { return nil }
    
    // Microsoft has a crazy shitty URL scheme for RDP (of course)
    // https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/dn690096(v=ws.11)
    var urlString = "\(service.scheme)://full%20address=s%3A\(self.host)%3A\(service.port)"
    if service.usesUsername, let username = username.trimmed?.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed) {
        urlString += "&username=s%3A\(username)"
    }
    
    // Password is not supported in the Microsoft scheme - so this will likely not work
    if service.usesPassword, let password = password.trimmed?.addingPercentEncoding(withAllowedCharacters: .urlPasswordAllowed) {
      urlString += "&password=s%3A\(password)"
    }
    
    // TODO: Consider adding settings to specify RDP specific options
    // I tried the desktop width and height settings but they did not appear to do anything
    urlString += "&screen%20mode%20id=i%3A1" // Run in a window

    return URL(string: urlString)
  }
  
  internal func fallback_url(for service: Service,
                             username: String,
                             password: String) -> URL?
  {
    var components  = URLComponents()
    components.host = self.host
    if service.usesUsername {
      components.user = username.trimmed
    }
    if service.usesPassword {
      components.password = password.trimmed
    }
    if service.port > 0 {
      components.port = service.port
    }
    if !service.scheme.isEmpty {
      components.scheme = service.scheme
    }
    return components.url
  }
}
