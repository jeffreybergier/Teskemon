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
  
  public struct Value: Codable {
    public var status: Tailscale.Status?
    public var nodeIDs: [Tailscale.Node.Identifier] = []
    public var nodes: [Tailscale.Node.Identifier: Tailscale.Node] = [:]
    public var users: [Tailscale.Node.Identifier: Tailscale.User] = [:]
    public var services: [Tailscale.Node.Identifier: Service.Status] = [:]
  }
  
  @JSBSceneStorage("ControllerValue") private var storage: Value = Value()
  @Services private var services
  @AppStorage("TailscaleExecutable") private var executable: String = "/usr/local/bin/tailscale"
  
  public init() {}
  
  public var wrappedValue: Value {
    return self.storage
  }
  
  public func updateMachines() async throws {
    let value = try await type(of: self).cliStatus(self.executable)
    self.storage.status = value.status
    self.storage.nodeIDs = Array(value.nodes.keys)
    self.storage.nodes = value.nodes
    self.storage.users = value.users
  }
  
  public func updateServices() async throws {
//    let nodes = self.storage?.nodes ?? []
//    self.storage?.nodes = try await type(of: self).serviceStatus(nodes: nodes,
//                                                                 services: self.services)
  }
}

extension Controller {
  
  internal static func serviceStatus(nodes: [Tailscale.Node], services: [Service]) async throws -> [Tailscale.Node] {
    guard !nodes.isEmpty, !services.isEmpty else { return nodes }
    var output = nodes
    for (index, node) in nodes.enumerated() {
      for service in services {
        let arguments: [String] = ["/usr/bin/nc", "-zv", "-w 5", node.url, String(describing: service.port)]
        NSLog("CHECKING: \(arguments)")
        let result = try await Process.execute(arguments: arguments)
        output[index].serviceStatus[service] = result.exitCode == 0
      }
    }
    NSLog("ALL CHECKED")
    return nodes
  }
  
  internal static func cliStatus(_ executable: String) async throws -> Tailscale.StatusValue {
    let decoder = JSONDecoder()
    let result = try await Process.execute(arguments: [executable, "status", "--json"])
    return try decoder.decode(Tailscale.Raw.Status.self, from: result.stdOut).clean()
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
  static func execute(arguments: [String]) async throws -> (exitCode: Int, stdOut: Data, errOut: Data) {
    try await withCheckedThrowingContinuation { continuation  in
      // Create files
      let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
      let url = tempURL.appendingPathComponent("0000_" + UUID().uuidString + ".stdout", isDirectory: false)
      let urlError = tempURL.appendingPathComponent("0000_" + UUID().uuidString + ".stderr", isDirectory: false)
      let fm = FileManager.default
      fm.createFile(atPath: url.path(), contents: nil)
      fm.createFile(atPath: urlError.path(), contents: nil)
      
      do {
        let task = Process()
        let handle = try FileHandle(forWritingTo: url)
        let errorHandle = try FileHandle(forWritingTo: urlError)
        
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = arguments
        task.standardOutput = handle
        task.standardError = errorHandle
        task.qualityOfService = .userInitiated
        
        task.terminationHandler = { task in
          do {
            try handle.close()
            try errorHandle.close()
            let stdOut = try Data(contentsOf: url)
            let errOut = try Data(contentsOf: urlError)
            let fm = FileManager.default
            try fm.removeItem(at: url)
            try fm.removeItem(at: urlError)
            continuation.resume(returning: (Int(task.terminationStatus), stdOut, errOut))
          } catch {
            continuation.resume(throwing: error)
          }
        }
        
        print(url.path())
        try task.run()
      } catch {
        continuation.resume(throwing: error)
      }
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
