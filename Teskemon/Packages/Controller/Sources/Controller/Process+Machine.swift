//
//  Created by Jeffrey Bergier on 2025/01/17.
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

extension Process {
  @MainActor
  internal static func machines(with executable: String) async throws -> MachineController.Value {
    let result = try await Process.execute(arguments: [executable, "status", "--json"])
    guard result.errOut.isEmpty else {
      throw result
    }
    let model = try MachineController.Value(data: result.stdOut)
    return model
  }
}


