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
  
  @TableController private var table
  @StatusController private var status
  @SettingsController private var settings
  @PresentationController private var presentation
  
  @State private var TEMP_isAutoUpdatingMachines = false
  @State private var TEMP_isAutoUpdatingServices = false
  
  public init() { }
  
  public var body: some View {
    NavigationStack {
      MachineTable(table: self.$table,
                   status: self.$status,
                   selection: self.$presentation.selection)
      .navigationTitle("テスケモン")
      .navigationSubtitle(self.navigationTitleAppendString)
        .sheet(items: self.$presentation.isShowingInfoPanel,
               content: { MachineInfoWindow(ids: $0) })
        .toolbar {
          ToolbarItem { self.appSettings     }
          ToolbarItem { self.machineSettings }
          ToolbarItem { self.refreshMenu     }
          ToolbarItem { self.statusMenu      }
        }
    }
  }
  
  private var navigationTitleAppendString: String {
    guard let tailscale = self.table.tailscale, let name = tailscale.currentTailnet?.name else { return "" }
    return name + "・" + tailscale.magicDNSSuffix 
  }
  
  private var machineSettings: some View {
    Menu {
      Section ("\(self.presentation.selection.count) Machine(s) Selected") {
        Button("Machine Information") {
          self.presentation.isShowingInfoPanel = self.presentation.selection
        }
        Button("Machine Names") {
          self.presentation.isShowingInfoPanel = self.presentation.selection
        }
        Button("Machine Passwords") {
          self.presentation.isShowingInfoPanel = self.presentation.selection
        }
      }
      Button("Deselect All") {
        self.presentation.selection = []
      }
    } label: {
      Label("Machine Settings", systemImage: "gearshape.2")
        .labelStyle(.titleAndIcon)
    }
  }
  
  private var appSettings: some View {
    Menu {
      Button("General") {
      }
      Button("Services") {
      }
    } label: {
      Label("App Settings", systemImage: "gearshape")
        .labelStyle(.titleAndIcon)
    }
  }
  
  private var refreshMenu: some View {
    Menu {
      Section("Machines") {
        Button("Refresh Machine Info", systemImage: "desktopcomputer") {
          self.performAsync { try await self._table.updateMachines(with: self.settings.executable) }
        }
        Toggle(isOn: self.$TEMP_isAutoUpdatingMachines) {
          Label("Automatically Refresh",
                systemImage: self.TEMP_isAutoUpdatingMachines
                ? "progress.indicator"
                : "square")
        }
      }
      Section("Services") {
        Button(self.presentation.selection.isEmpty
               ? "Refresh All Services"
               : "Refresh Services for \(self.presentation.selection.count) Machine(s)",
          systemImage: "network")
        {
          self.performAsync {
            try await self._status.updateStatus(for: self.settings.services,
                                                on: self.table.machines(for: self.presentation.selection),
                                                timeout: self.settings.timeout,
                                                batchSize: self.settings.batchSize)
          }
        }
        Toggle(isOn: self.$TEMP_isAutoUpdatingServices) {
          Label("Automatically Refresh",
                systemImage: self.TEMP_isAutoUpdatingServices
                ? "progress.indicator"
                : "square")
        }
      }
      Button("Reset Data", systemImage: "trash") {
        self._status.resetData()
        self._table.resetData()
      }
    } label: {
      Label("Refresh", systemImage: "arrow.clockwise")
    }
    .labelStyle(.titleAndIcon)
  }
  
  private func performAsync(function: @escaping (() async throws -> Void)) {
    Task {
      do {
        try await function()
      } catch {
        // TODO: Show error in UI
        NSLog(String(describing:error))
      }
    }
  }
  
  private var statusMenu: some View {
    Menu {
      Section("Tailscale") {
        switch (self.table.tailscale?.backendState) {
        case .some(let value) where value == "Running":
          Label(self.table.tailscale?.backendState ?? "–", systemImage: "circle.fill")
            .foregroundStyle(Color(nsColor: .systemGreen).gradient, .black.gradient)
        case .some(let value) where value == "Stopped":
          Label(value, systemImage: "stop.fill")
            .foregroundStyle(Color(nsColor: .systemRed).gradient, .black.gradient)
        case .some(let value):
          Label(value, systemImage: "triangle.fill")
            .foregroundStyle(Color(nsColor: .systemYellow).gradient, .black.gradient)
        case .none:
          Label("–", systemImage: "triangle.fill")
        }
      }
      Section("Account") {
        Label(self.table.tailscale?.currentTailnet?.name ?? "–", systemImage: "person.circle")
      }
      Section("Domain") {
        Label(self.table.tailscale?.magicDNSSuffix ?? "–", systemImage: "network")
      }
      switch (self.table.tailscale) {
      case .some(let tailscale) where tailscale.versionUpToDate == true:
        Section("Version – Up to Date") {
          Label(tailscale.version, systemImage: "circle.fill")
            .foregroundStyle(Color(nsColor: .systemGreen).gradient, .black)
        }
      case .some(let tailscale):
        Section("Version – Update Available") {
          Label(tailscale.version, systemImage: "triangle.fill")
            .foregroundStyle(Color(nsColor: .systemYellow).gradient, .black)
        }
      case .none:
        Section("Version") {
          Label("–", systemImage: "triangle.fill")
        }
      }
      Section("MagicDNS") {
        switch (self.table.tailscale?.currentTailnet?.magicDNSEnabled) {
        case .some(let magicDNSEnabled) where magicDNSEnabled == true:
          Label("Enabled", systemImage: "circle.fill")
            .foregroundStyle(Color(nsColor: .systemGreen).gradient, .black)
        case .some(_):
          Label("Disabled", systemImage: "stop.fill")
            .foregroundStyle(Color(nsColor: .systemRed).gradient, .black)
        case .none:
          Label("–", systemImage: "triangle.fill")
        }
      }
      Section("Tunneling") {
        switch (self.table.tailscale?.tunnelingEnabled) {
        case .some(let tunnelingEnabled) where tunnelingEnabled == true:
          Label("Enabled", systemImage: "circle.fill")
            .foregroundStyle(Color(nsColor: .systemGreen).gradient, .black)
        case .some(_):
          Label("Disabled", systemImage: "stop.fill")
            .foregroundStyle(Color(nsColor: .systemRed).gradient, .black)
        case .none:
          Label("–", systemImage: "triangle.fill")
        }
      }
      Section("Node Key") {
        switch (self.table.tailscale?.haveNodeKey) {
        case .some(let haveNodeKey) where haveNodeKey == true:
          Label("Present", systemImage: "circle.fill")
            .foregroundStyle(Color(nsColor: .systemGreen).gradient, .black)
        case .some(_):
          Label("Missing", systemImage: "stop.fill")
            .foregroundStyle(Color(nsColor: .systemRed).gradient, .black)
        case .none:
          Label("–", systemImage: "triangle.fill")
        }
      }
      Button("Select this Machine", systemImage: "cursorarrow.rays") {
        self.presentation.selection = self.table.tailscale?.selfNodeID.map { [$0] } ?? []
      }
      .disabled(self.table.tailscale?.selfNodeID == nil)
    } label: {
      switch (self.table.tailscale?.backendState) {
      case .some(let value) where value == "Running":
        Label(self.table.tailscale?.backendState ?? "–", systemImage: "circle.fill")
          .foregroundStyle(Color(nsColor: .systemGreen).gradient, .black.gradient)
      case .some(let value) where value == "Stopped":
        Label(value, systemImage: "stop.fill")
          .foregroundStyle(Color(nsColor: .systemRed).gradient, .black.gradient)
      case .some(let value):
        Label(value, systemImage: "triangle.fill")
          .foregroundStyle(Color(nsColor: .systemYellow).gradient, .black.gradient)
      case .none:
        Label("No Data", systemImage: "questionmark.square.dashed")
      }
    }
    .labelStyle(.titleAndIcon)
  }
}
