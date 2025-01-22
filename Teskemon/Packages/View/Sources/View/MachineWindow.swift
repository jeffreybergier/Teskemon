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
import Controller

public struct MachineWindow: View {
  
  @State private var isAwaiting = false
  @TableController private var table
  @StatusController private var status
  @SettingsController private var settings
  @PresentationController private var presentation
  
  public init() { }
  
  public var body: some View {
    NavigationStack {
      MachineTable(table: self.$table,
                   status: self.$status,
                   selection: self.$presentation.selection)
        .navigationTitle(self.table.tailscale?.currentTailnet?.name ?? "テスケモン")
        .sheet(items: self.$presentation.isShowingInfoPanel,
               content: { MachineInfoWindow(ids: $0) })
        .toolbar {
          ToolbarItem { self.infoButton     }
          ToolbarItem { self.machineButton  }
          ToolbarItem { self.servicesButton }
          ToolbarItem(placement: .accessoryBar(id: "Status")) { self.resetButton }
          ToolbarItem(placement: .accessoryBar(id: "Status")) { Spacer() }
          ToolbarItem(placement: .accessoryBar(id: "Status")) {
            Menu {
              Section("Something 1") {
                Label("Connected", systemImage: "circle.fill")
                  .foregroundStyle(Color(nsColor: .systemGreen))
              }
              Section("Something 1") {
                Label("Connected", systemImage: "circle.fill")
                  .foregroundStyle(Color(nsColor: .systemGreen))
              }
            } label: {
              Label("Connected", systemImage: "circle.fill")
                .foregroundStyle(Color(nsColor: .systemGreen))
            }
            .labelStyle(.titleAndIcon)
          }
        }
    }
  }
  
  private var infoButton: some View {
    Button("Machine Info", systemImage: "info.circle") {
      self.presentation.isShowingInfoPanel = self.presentation.selection
    }
    .disabled(self.presentation.selection.isEmpty)
  }
  
  private var machineButton: some View {
    Button("Update Machines", systemImage: self.isAwaiting ? "progress.indicator" : "desktopcomputer.and.arrow.down") {
      self.performAsync { try await self._table.updateMachines(with: self.settings.executable) }
    }
    .disabled(self.isAwaiting)
  }
  
  private var servicesButton: some View {
    Button("Update Services", systemImage: self.isAwaiting ? "progress.indicator" : "slider.horizontal.2.arrow.trianglehead.counterclockwise")
    {
      self.performAsync {
        try await self._status.updateStatus(for: self.settings.services,
                                            on: self.table.machines(for: self.presentation.selection),
                                            timeout: self.settings.timeout,
                                            batchSize: self.settings.batchSize)
      }
    }
    .disabled(self.isAwaiting)
  }
    
  private var resetButton: some View {
    Button("Reset Data", systemImage: "trash") {
      self._status.resetData()
      self._table.resetData()
    }
    .disabled(self.isAwaiting)
  }
  
  private func performAsync(function: @escaping (() async throws -> Void)) {
    self.isAwaiting = true
    Task {
      do {
        try await function()
        self.isAwaiting = false
      } catch {
        // TODO: Show error in UI
        NSLog(String(describing:error))
        self.isAwaiting = false
      }
    }
  }
}
