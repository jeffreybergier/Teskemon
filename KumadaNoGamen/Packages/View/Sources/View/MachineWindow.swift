//
//  Created by Jeffrey Bergier on 2025/01/12.
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
  
  @State private var isAwaiting = false
  @TableController private var controller
  @SettingsController private var settings
  
  public init() { }
  
  public var body: some View {
    NavigationStack {
      MachineTable(model: self.$controller, services: self.$settings.services)
        .navigationTitle(self.controller.tailscale?.currentTailnet?.name ?? "テスケモン")
        .toolbar {
          ToolbarItem {
            Button("Machines", systemImage: self.isAwaiting ? "progress.indicator" : "desktopcomputer") {
              self.isAwaiting = true
              Task {
                try await self._controller.updateMachines()
                self.isAwaiting = false
              }
            }
            .disabled(self.isAwaiting)
          }
          ToolbarItem {
            Button("Services", systemImage: self.isAwaiting ? "progress.indicator" : "network") {
              self.isAwaiting = true
              Task {
                try await self._controller.updateServices()
                self.isAwaiting = false
              }
            }
            .disabled(self.isAwaiting)
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
