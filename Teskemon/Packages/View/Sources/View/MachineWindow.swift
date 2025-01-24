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
  private var selectionForMenus: Set<Machine.Identifier> {
    return self.presentation.selection.isEmpty
           ? Set(self.table.lookUp.keys)
           : self.presentation.selection
  }
  
  public init() { }
  
  public var body: some View {
    NavigationStack {
      MachineTable(table: self.$table,
                   status: self.$status,
                   selection: self.$presentation.selection)
      .navigationTitle("テスケモン")
      .navigationSubtitle(self.navigationTitleAppendString)
      .sheet(item: self.$presentation.showInfoPanel,
             content: { MachineInfoPanel($0) })
      .toolbar {
        ToolbarItem { self.editMenu }
        ToolbarItem { self.refreshMenu     }
        ToolbarItem { self.statusMenu      }
      }
    }
  }
  
  private var navigationTitleAppendString: String {
    guard let tailscale = self.table.tailscale, let name = tailscale.currentTailnet?.name else { return "" }
    return name + "・" + tailscale.magicDNSSuffix 
  }
  
  private var editMenu: some View {
    Menu {
      Section (self.presentation.selection.isEmpty
               ? "Edit All Machines"
               : "Edit \(self.selectionForMenus.count) Machine(s)")
      {
        Button("Information", systemImage: "info") {
          self.presentation.showInfoPanel = .init(tab: 0, self.selectionForMenus)
        }
        Button("Names", systemImage: "person") {
          self.presentation.showInfoPanel = .init(tab: 1, self.selectionForMenus)
        }
        Button("Passwords", systemImage: "lock") {
          self.presentation.showInfoPanel = .init(tab: 2, self.selectionForMenus)
        }
      }
      Button("Deselect All", systemImage: "cursorarrow.slash") {
        self.presentation.selection = []
      }
      .disabled(self.presentation.selection.isEmpty)
    } label: {
      Label("Edit", systemImage: "desktopcomputer")
    }
    .labelStyle(.titleAndIcon)
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
                                                on: self.table.machines(for: self.selectionForMenus),
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
}
