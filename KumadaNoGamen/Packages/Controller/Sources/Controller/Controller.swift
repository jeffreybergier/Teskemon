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
import Model
import Umbrella

@MainActor
@propertyWrapper
public struct Controller: DynamicProperty {
  
  public struct Value: Codable {
    public var tailscale:  Tailscale?
    public var machineIDs: [Machine.Identifier] = []
    public var machines:   [Machine.Identifier: Machine] = [:]
    public var users:      [Machine.Identifier: User] = [:]
    public var services:   [Machine.Identifier: [Service: Service.Status]] = [:]
  }
  
  @JSBSceneStorage("ControllerValue") private var storage: Value = Value()
  @AppStorage("TailscaleLocation") private var location: String = "/usr/local/bin/tailscale"
  @Services private var services
  
  public init() {}
  
  public var wrappedValue: Value {
    return self.storage
  }
  
  public func updateMachines() async throws {
    let value = try await type(of: self).getTailscale(self.location)
    self.storage.tailscale = value.tailscale
    self.storage.machineIDs = Array(value.machines.keys.sorted(by: { $0.rawValue > $1.rawValue }))
    self.storage.machines = value.machines
    self.storage.users = value.users
  }
  
  public func updateServices() async throws {
    self.storage.services = try await type(of: self).getStatus(for: self.services,
                                                               on: self.storage.machines)
  }
}

extension Controller {
  
  internal static func getStatus(for services: [Service],
                                 on machines: [Machine.Identifier: Machine]) async throws
                                 -> [Machine.Identifier: [Service: Service.Status]]
  {
    guard !machines.isEmpty, !services.isEmpty else { return [:] }
    let timeout = 3
    var output: [Machine.Identifier: [Service: Service.Status]] = [:]
    for (id, node) in machines {
      var status: [Service: Service.Status] = [:]
      for service in services {
        let arguments: [String] = ["/usr/bin/nc", "-zv", "-G \(timeout)", "-w \(timeout)", node.url, String(describing: service.port)]
        let result = try await Process.execute(arguments: arguments)
        // Not sure why the output always comes through Standard Error with NC
        let output = String(data: result.errOut, encoding: .utf8)!
        if output.hasSuffix("succeeded!\n") {
          NSLog("OPEN: \(arguments)")
          status[service] = .online
        } else if output.hasSuffix("refused\n") {
          NSLog("CLSD: \(arguments)")
          status[service] = .offline
        } else if output.hasSuffix("Operation timed out\n") {
          NSLog("TMOT: \(arguments)")
          status[service] = .error
        } else {
          assertionFailure()
          NSLog("ERRR: \(arguments)")
          status[service] = .error
        }
      }
      output[id] = status
    }
    return output
  }
  
  internal static func getTailscale(_ location: String) async throws -> Tailscale.Refresh {
    let data = try await Process.execute(arguments: [location, "status", "--json"]).stdOut
    return try Tailscale.Refresh.new(data: data)
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
  static func execute(url: URL = URL(fileURLWithPath: "/usr/bin/env"),
                      arguments: [String]) async throws
                      -> (exitCode: Int, stdOut: Data, errOut: Data)
  {
    try await withCheckedThrowingContinuation { continuation  in
      let tempURL   = URL(fileURLWithPath: NSTemporaryDirectory())
      let stdOutURL = tempURL.appendingPathComponent("com.saturdayapps.kumadanogamen." + UUID().uuidString + ".stdout", isDirectory: false)
      let stdErrURL = tempURL.appendingPathComponent("com.saturdayapps.kumadanogamen." + UUID().uuidString + ".stderr", isDirectory: false)
      FileManager.default.createFile(atPath: stdOutURL.path(), contents: nil)
      FileManager.default.createFile(atPath: stdErrURL.path(), contents: nil)
      
      do {
        let task = Process()
        let stdOutHandle = try FileHandle(forWritingTo: stdOutURL)
        let stdErrHandle = try FileHandle(forWritingTo: stdErrURL)
        
        task.executableURL    = url
        task.arguments        = arguments
        task.standardOutput   = stdOutHandle
        task.standardError    = stdErrHandle
        task.qualityOfService = .userInitiated
        
        task.terminationHandler = { task in
          do {
            try stdOutHandle.close()
            try stdErrHandle.close()
            let stdOut = try Data(contentsOf: stdOutURL)
            let errOut = try Data(contentsOf: stdErrURL)
            try FileManager.default.removeItem(at: stdOutURL)
            try FileManager.default.removeItem(at: stdErrURL)
            continuation.resume(returning: (Int(task.terminationStatus), stdOut, errOut))
          } catch {
            continuation.resume(throwing: error)
          }
        }
        
        try task.run()
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }
}
