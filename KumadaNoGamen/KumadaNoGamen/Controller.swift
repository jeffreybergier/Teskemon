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
//  along with WaterMe.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

public struct Controller {
  internal static func tailscaleStatus() -> Tailscale.Raw.Status? {
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
      
      return output
    } catch {
      print("Failed to execute process: \(error)")
      return nil
    }
  }
}
