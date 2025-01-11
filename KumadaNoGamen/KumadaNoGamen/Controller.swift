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
  
  @JSBSceneStorage(defaultValue: nil, key:"CLIStatus") private var storage: Tailscale.Status?
  @Services private var services
  @AppStorage("TailscaleExecutable") private var executable: String = "/usr/local/bin/tailscale"
  
  public init() {}
  
  public var wrappedValue: Tailscale.Status? {
    return self.storage
  }
  
  public func updateAll() async throws {
    var storage = try await type(of: self).cliStatus(self.executable)
    storage.nodes = try await type(of: self).serviceStatus(nodes: storage.nodes, services: self.services)
    self.storage = storage
  }
  
  public func updateCLI() async throws {
    self.storage = try await type(of: self).cliStatus(self.executable)
  }
  
  public func updateServices() async throws {
    let nodes = self.storage?.nodes ?? []
    self.storage?.nodes = try await type(of: self).serviceStatus(nodes: nodes,
                                                      services: self.services)
  }
}

extension Controller {
  
  internal static func serviceStatus(nodes: [Tailscale.Node], services: [Service]) async throws -> [Tailscale.Node] {
    guard !nodes.isEmpty, !services.isEmpty else { return nodes }
    var output = nodes
    for (index, node) in nodes.enumerated() {
      for service in services {
        let arguments: [String] = ["/usr/bin/nc", "-z", node.url, String(describing: service.port)]
        NSLog("CHECKING: \(arguments)")
        let result = try await Process.execute(arguments: arguments)
        output[index].serviceStatus[service] = result.exitCode == 0
      }
    }
    NSLog("ALL CHECKED")
    return nodes
  }
  
  internal static func cliStatus(_ executable: String) async throws -> Tailscale.Status {
    
    let result = try await Process.execute(arguments: [executable, "status", "--json"])
    assert(result.exitCode == 0, "")
    let decoder = JSONDecoder()
    let output = try decoder.decode(Tailscale.Raw.Status.self, from: result.data)
    
    return output.clean()
  }
}

@MainActor
@propertyWrapper
public struct Services: DynamicProperty {
  
  public init() { }
  
  public var wrappedValue: [Service] {
    get { Service.default }
    nonmutating set { fatalError("// TODO: Add this to NSUserDefaults") }
  }
}

extension Process {
  static func execute(arguments: [String]) async throws -> (exitCode: Int, data: Data) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = arguments
    
    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    
    try process.run()
    process.waitUntilExit()
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    
    return (Int(process.terminationStatus), outputData)
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
    
    public init(defaultValue: Value, key: String, onError: OnError? = nil) {
        _rawValue = .init(key)
        _helper = .init(wrappedValue: .init(onError))
        self.defaultValue = defaultValue
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
