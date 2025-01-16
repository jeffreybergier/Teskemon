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
import Controller

public struct MachineWindow: View {
  
  @TableController private var controller
  
  public init() { }
  
  public var body: some View {
    NavigationStack {
      MachineTable()
        .navigationTitle(self.controller.tailscale?.currentTailnet?.name ?? "熊田の画面")
        .toolbar {
          ToolbarItem {
            Button("Machines", systemImage: "desktopcomputer")
            {
              Task {
                do {
                  try await self._controller.updateMachines()
                } catch {
                  NSLog("// TODO: Show an error dialog")
                }
              }
            }
          }
          ToolbarItem {
            Button("Services", systemImage: "network")
            {
              Task {
                do {
                  try await self._controller.updateServices()
                } catch {
                  NSLog("// TODO: Show an error dialog")
                }
              }
            }
          }
          ToolbarItem {
            Button("Reset Data", systemImage: "trash")
            {
              self._controller.resetData()
            }
          }
        }
    }
  }
}
