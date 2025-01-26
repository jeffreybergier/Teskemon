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
  
  @MachineController  private var machines
  @ServiceController  private var services
  @SettingsController private var settings
  @PresentationController private var presentation
  @TimerProperty private var timer
  
  private var selectionForMenus: Set<Machine.Identifier> {
    return self.presentation.selection.isEmpty
           ? self.machines.allIdentifiers()
           : self.presentation.selection
  }
  
  public init() { }
  
  public var body: some View {
    NavigationStack {
      MachineTable(machines: self.$machines,
                   services: self.$services,
                   selection: self.$presentation.selection)
      .overlay(alignment: .topTrailing) {
          ProgressView(value: Double(self.services.progress.completedUnitCount),
                       total: Double(self.services.progress.totalUnitCount))
          .progressViewStyle(.linear)
          .padding(EdgeInsets(top: 4,
                              leading: 12,
                              bottom: 5,
                              trailing: 12))
          .background {
            UnevenRoundedRectangle(bottomLeadingRadius: 4,
                                   style: .continuous)
              .fill(.ultraThinMaterial)
          }
          .frame(width: 280)
          .opacity(self.services.isLoading ? 1 : 0)
          .offset(y: self.services.isLoading ? 0 : -20)
      }
      .animation(.default, value: self.services.isLoading)
      .animation(.default, value: self.settings.statusTimer.automatic)
      .navigationTitle("テスケモン")
      .navigationSubtitle(self.navigationTitleAppendString)
      .sheet(item: self.$presentation.showInfoPanel,
             content: { InfoSheet($0) })
      .onChange(of: self.timer.hasElapsed(seconds: self.settings.machineTimer.interval), initial: true) { _, fired in
        guard self.settings.machineTimer.automatic, fired else { return }
        self.performAsync {
          try await self._machines.updateMachines(with: self.settings.executable)
        }
      }
      .onChange(of: self.timer.hasElapsed(seconds: self.settings.statusTimer.interval), initial: true) { _, fired in
        guard self.settings.statusTimer.automatic, fired else { return }
        self.performAsync {
          try await self._services.updateStatus(for: self.settings.services,
                                              on: self.machines.allMachines(),
                                              timeout: self.settings.timeout,
                                              batchSize: self.settings.batchSize)
        }
      }
      .toolbar {
        ToolbarItem { self.editMenu    }
        ToolbarItem { self.refreshMenu }
        ToolbarItem { self.statusMenu  }
      }
    }
  }
  
  private var navigationTitleAppendString: String {
    guard let tailscale = self.machines.tailscale, let name = tailscale.currentTailnet?.name else { return "" }
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
      Label.edit
    }
    .labelStyle(.titleAndIcon)
  }
  
  private var refreshMenu: some View {
    Menu {
      Section (self.presentation.selection.isEmpty
               ? "Refresh All Machines"
               : "Refresh \(self.selectionForMenus.count) Machine(s)")
      {
        Button("Machines", systemImage: "person.2.arrow.trianglehead.counterclockwise") {
          self.performAsync {
            try await self._machines.updateMachines(with: self.settings.executable)
          }
        }
        .disabled(self.isAwaitingRefresh)
        Button("Services", systemImage: "slider.horizontal.2.arrow.trianglehead.counterclockwise") {
          self.performAsync {
            try await self._services.updateStatus(for: self.settings.services,
                                                on: self.machines.machines(for: self.selectionForMenus),
                                                timeout: self.settings.timeout,
                                                batchSize: self.settings.batchSize)
          }
        }
        .disabled(self.isAwaitingRefresh)
      }
      Section("Automatic Refresh") {
        Toggle(isOn: self.$settings.machineTimer.automatic) {
          self.settings.machineTimer.automatic
              ? Label.machinesRefreshOn
              : Label.machinesRefreshOff
        }
        Toggle(isOn: self.$settings.statusTimer.automatic) {
          self.settings.statusTimer.automatic
              ? Label.servicesRefreshOn
              : Label.servicesRefreshOff
        }
      }
      Button("Deselect All", systemImage: "cursorarrow.slash") {
        self.presentation.selection = []
      }
      .disabled(self.presentation.selection.isEmpty)
      Button("Clear Cache", systemImage: "trash") {
        self._services.resetData()
        self._machines.resetData()
      }
      .disabled(self.isAwaitingRefresh)
    } label: {
      Label {
        Text("Refresh")
      } icon: {
        switch (self.isAwaitingRefresh, self.settings.statusTimer.automatic) {
        case (true, _):
          Image(systemName: "progress.indicator")
        case (false, false):
          Image(systemName: "arrow.clockwise")
        case (false, true):
          Image(systemName: "autostartstop")
        }
      }


    }
    .labelStyle(.titleAndIcon)
  }
  
  private var isAwaitingRefresh: Bool {
    self.machines.isLoading || self.services.isLoading
  }
  
  private var statusMenu: some View {
    Menu {
      Section("Tailscale") {
        switch (self.machines.tailscale?.backendState) {
        case .some(let value) where value == "Running":
          Label.statusEnabled(self.machines.tailscale?.backendState)
        case .some(let value) where value == "Stopped":
          Label.statusDisabled(value)
        case .some(let value):
          Label.statusUnknown(value)
        case .none:
          Label.statusUnknown
        }
      }
      Section("Account") {
        Label.personCircle(self.machines.tailscale?.currentTailnet?.name)
      }
      Section("Domain") {
        Label.network(self.machines.tailscale?.magicDNSSuffix)
      }
      switch (self.machines.tailscale) {
      case .some(let tailscale) where tailscale.versionUpToDate == true:
        Section("Version – Up to Date") {
          Label.statusEnabled(tailscale.version)
        }
      case .some(let tailscale):
        Section("Version – Update Available") {
          Label.statusUnknown(tailscale.version)
        }
      case .none:
        Section("Version") {
          Label.statusUnknown
        }
      }
      Section("MagicDNS") {
        switch (self.machines.tailscale?.currentTailnet?.magicDNSEnabled) {
        case .some(let magicDNSEnabled) where magicDNSEnabled == true:
          Label.statusEnabled
        case .some(_):
          Label.statusDisabled
        case .none:
          Label.statusUnknown
        }
      }
      Section("Tunneling") {
        switch (self.machines.tailscale?.tunnelingEnabled) {
        case .some(let tunnelingEnabled) where tunnelingEnabled == true:
          Label.statusEnabled
        case .some(_):
          Label.statusDisabled
        case .none:
          Label.statusUnknown
        }
      }
      Section("Node Key") {
        switch (self.machines.tailscale?.haveNodeKey) {
        case .some(let haveNodeKey) where haveNodeKey == true:
          Label.statusEnabled("Present")
        case .some(_):
          Label.statusDisabled("Missing")
        case .none:
          Label.statusUnknown
        }
      }
      Button("Select this Machine", systemImage: "cursorarrow.rays") {
        self.presentation.selection = self.machines.tailscale?.selfNodeID.map { [$0] } ?? []
      }
      .disabled(self.machines.tailscale?.selfNodeID == nil)
    } label: {
      switch (self.machines.tailscale?.backendState) {
      case .some(let value) where value == "Running":
        Label.statusEnabled(value)
      case .some(let value) where value == "Stopped":
        Label.statusDisabled(value)
      case .some(let value):
        Label.statusUnknown(value)
      case .none:
        Label.noData
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
