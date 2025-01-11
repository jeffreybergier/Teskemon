//
//  Created by Jeffrey Bergier on 15/1/18.
//  Copyright © 2025 Saturday Apps.
//
//  This file is part of KumadaNoGamen, a macOS App.
//
//  KumadaNoGamen is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  KumadaNoGamen is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with KumadaNoGamen.  If not, see <http://www.gnu.org/licenses/>.
//

import SwiftUI

@MainActor
@propertyWrapper
public struct Controller: DynamicProperty {
  @JSBSceneStorage(wrappedValue: nil, "cliStatus") private var cliStatus: Tailscale.Status?
  public init() {}
  public var wrappedValue: Tailscale.Status? {
    return self.cliStatus
  }
  public func updateAll() {
    self.cliStatus = type(of: self).cliStatus()
  }
}

extension Controller {
  internal static func cliStatus() -> Tailscale.Status? {
    // Create a Process instance
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env") // Use `/usr/bin/env` to locate the command
    process.arguments = ["/usr/local/bin/tailscale", "status", "--json"]
    
    // Pipe to capture output
    let pipe = Pipe()
    process.standardOutput = pipe
    
    do {
      // Launch the process
      try process.run()
      process.waitUntilExit() // Wait for the command to finish executing
      
      // Check the process exit status
      guard process.terminationStatus == 0 else {
        NSLog("Process failed with exit code: \(process.terminationStatus)")
        return nil
      }
      
      // Decode the JSON
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      let decoder = JSONDecoder()
      let output = try decoder.decode(Tailscale.Raw.Status.self, from: data)
      
      return output.clean()
    } catch {
      print("Failed to execute process: \(error)")
      return nil
    }
  }
}


// TODO: Delete after importing Umbrella via SPM
/// Provides a SceneStorage API that takes any codable value
@MainActor
@propertyWrapper
public struct JSBSceneStorage<Value: Codable>: DynamicProperty {
    
    @SceneStorage private var rawValue: String?
    @StateObject  private var helper: CodableStorageHelper<Value>
    
    private let defaultValue: Value
    
    public init(wrappedValue: Value, _ key: String, onError: OnError? = nil) {
        _rawValue = .init(key)
        _helper = .init(wrappedValue: .init(onError))
        self.defaultValue = wrappedValue
    }
    
    public var wrappedValue: Value {
        get { self.helper.readCacheOrDecode(self.rawValue) ?? self.defaultValue }
        nonmutating set { self.rawValue = self.helper.encodeAndCache(newValue) }
    }
    
    public var projectedValue: Binding<Value> {
        Binding {
            self.wrappedValue
        } set: {
            self.wrappedValue = $0
        }
    }
}

public typealias OnError = (Error) -> Void

internal class CodableStorageHelper<Value: Codable>: ObservableObject {
    
    // Not sure if storing these helps performance
    private let encoder = PropertyListEncoder()
    private let decoder = PropertyListDecoder()
    
    // Not sure if cache actually helps performance
    private var cache: [String: Value] = [:]
    private let onError: OnError?
    
    internal init(_ onError: OnError?) {
        self.onError = onError
    }
    
    internal func readCacheOrDecode(_ rawValue: String?) -> Value? {
        do {
            guard let rawValue else { return nil }
            if let cache = self.cache[rawValue] { return cache }
            guard let data = Data(base64Encoded: rawValue) else { return nil }
            return try self.decoder.decode(Value.self, from: data)
        } catch {
            self.onError?(error)
            guard self.onError == nil else { return nil }
            NSLog(String(describing: error))
            assertionFailure(String(describing: error))
            return nil
        }
    }
    
    internal func encodeAndCache(_ newValue: Value) -> String? {
        do {
            let data = try self.encoder.encode(newValue)
            let rawValue = data.base64EncodedString()
            self.cache[rawValue] = newValue
            return rawValue
        } catch {
            self.onError?(error)
            guard self.onError == nil else { return nil }
            NSLog(String(describing: error))
            assertionFailure(String(describing: error))
            return nil
        }
    }
}
