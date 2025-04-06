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
  @TimerProperty(identifier: "MachineWindow:Machine")
  private var machineTimer
  @TimerProperty(identifier: "MachineWindow:Status")
  private var statusTimer
  @TimerProperty(identifier: "SpinnerTimer")
  private var spinnerTimer
  @Environment(\.appearsActive) private var appearsActive
  
  private var selectionForMenus: Set<Machine.Identifier> {
    return self.presentation.tableSelection.isEmpty
         ? self.machines.allIdentifiers()
         : self.presentation.tableSelection
  }
  
  @State private var processError: CustomNSError?
  
  public init() { }
  
  public var body: some View {
    NavigationStack {
      MachineTable()
        .overlay(alignment: .top) {
          ProgressView(value: Double(self.services.progress.completedUnitCount),
                       total: Double(self.services.progress.totalUnitCount))
          .progressViewStyle(.linear)
          .padding(EdgeInsets(top: -6, leading: 0, bottom: 0, trailing: 0))
          .opacity(self.services.isLoading ? 1 : 0)
        }
        .animation(.default, value: self.services.isLoading)
        .animation(.default, value: self.settings.statusTimer.automatic)
        .navigationTitle(.appName)
        .navigationSubtitle(self.navigationTitleAppendString)
        .sheet(isPresented: self.$presentation.infoPanel.isPresented) {
          MachineInfo(selection: self.selectionForMenus)
        }
        .onChange(of: self.machineTimer.fireCount, initial: true) { _, _ in
          guard self.settings.machineTimer.automatic else { return }
          self.performAsync {
            try await self._machines.updateMachines(with: self.settings.executable)
          }
        }
        .onChange(of: self.statusTimer.fireCount, initial: true) { _, _ in
          guard self.settings.statusTimer.automatic else { return }
          self.performAsync {
            try await self._services.updateStatus(for:    self.settings.services,
                                                  on:     self.machines.allMachines(),
                                                  config: self.settings.scanning)
          }
        }
        .onChange(of: self.settings.machineTimer, initial: true) { _, newValue in
          self.machineTimer.interval = newValue.automatic ? newValue.interval : 0
        }
        .onChange(of: self.settings.statusTimer, initial: true) { _, newValue in
          self.statusTimer.interval  = newValue.automatic ? newValue.interval : 0
        }
        .onChange(of: self.appearsActive, initial: true) { _, appearsActive in
          self.spinnerTimer.interval = appearsActive ? 1.0 : 0
        }
        .toolbar {
          ToolbarItem { self.editMenu    }
          ToolbarItem { self.refreshMenu }
          ToolbarItem { self.statusMenu  }
        }
        .alert(error: self.$processError)
    }
  }
  
  private var navigationTitleAppendString: String {
    guard let tailscale = self.machines.tailscale, let name = tailscale.currentTailnet?.name else { return "" }
    return name + "・" + tailscale.magicDNSSuffix
  }
  
  private var editMenu: some View {
    Menu {
      Section(.selected(self.presentation.tableSelection.count)) {
        let action: (Presentation.InfoPanelTab) -> Void = { selectedTab in
          self.presentation.infoPanel = .init(
            tab: selectedTab,
            selection: self.selectionForMenus
          )
        }
        Button(.information, systemImage: .imageInfo)      { action(.info)      }
        Button(.names,       systemImage: .imagePerson)    { action(.names)     }
        Button(.passwords,   systemImage: .imagePasswords) { action(.passwords) }
      }
      Button(.verbDeselectAll, systemImage: .imageDeselect) {
        self.presentation.tableSelection = []
      }
      .disabled(self.presentation.tableSelection.isEmpty)
    } label: {
      Label(.edit, systemImage: .imageMachine)
    }
    .labelStyle(.titleAndIcon)
  }
  
  private var refreshMenu: some View {
    Menu {
      Section(.selected(self.presentation.tableSelection.count)) {
        Button(.machines, systemImage: .imageRefreshMachines) {
          self.performAsync {
            try await self._machines.updateMachines(with: self.settings.executable)
          }
        }
        .disabled(self.isAwaitingRefresh)
        Button(.services, systemImage: .imageRefreshServices) {
          self.performAsync {
            try await self._services.updateStatus(for:    self.settings.services,
                                                  on:     self.machines.machines(for: self.selectionForMenus),
                                                  config: self.settings.scanning)
          }
        }
        .disabled(self.isAwaitingRefresh)
      }
      Section(.refreshAuto) {
        Toggle(isOn: self.$settings.machineTimer.automatic) {
          self.settings.machineTimer.automatic
              ? Label(.machines, systemImage: .imageRefreshAutoOn)
              : Label(.machines, systemImage: .imageRefreshAutoOff)
        }
        Toggle(isOn: self.$settings.statusTimer.automatic) {
          self.settings.statusTimer.automatic
              ? Label(.services, systemImage: .imageRefreshAutoOn)
              : Label(.services, systemImage: .imageRefreshAutoOff)
        }
      }
      Button(.verbDeselectAll, systemImage: .imageDeselect) {
        self.presentation.tableSelection = []
      }
      .disabled(self.presentation.tableSelection.isEmpty)
      Button(.clearCache, systemImage: .imageTrash) {
        self._services.resetData()
        self._machines.resetData()
      }
      .disabled(self.isAwaitingRefresh)
    } label: {
      Label {
        Text(.refresh)
      } icon: {
        switch (self.isAwaitingRefresh, self.settings.statusTimer.automatic) {
        case (true, _):
          Image(systemName: .imageStatusProcessing,
                variableValue: self.spinnerTimer.percentage(of: 10))
        case (false, false):
          Image(systemName: .imageRefresh)
        case (false, true):
          Image(systemName: .imageRefreshAutoOn)
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
      let tailscale = self.machines.tailscale
      let user = tailscale?.selfUserID.map { self.machines.users[$0] } ?? nil
      Section(.tailscale) {
        switch tailscale?.backendState {
        case .some(let value) where value == "Running":
          Label(value, systemImage: .imageStatusOnline)
            .foregroundStyle(Color.statusOnline, Color.HACK_showColorInMenus)
        case .some(let value) where value == "Stopped":
          Label(value, systemImage: .imageStatusOffline)
            .foregroundStyle(Color.statusOffline, Color.HACK_showColorInMenus)
        case .some(let value):
          Label(value, systemImage: .imageStatusUnknown)
            .foregroundStyle(Color.statusUnknown, Color.HACK_showColorInMenus)
        case .none:
          Label(.noValue, systemImage: .imageStatusUnknown)
        }
      }
      switch (tailscale) {
      case .some(let tailscale) where tailscale.versionUpToDate == true:
        Section(.versionNew) {
          Label(tailscale.version, systemImage: .imageStatusOnline)
            .foregroundStyle(Color.statusOnline, Color.HACK_showColorInMenus)
        }
      case .some(let tailscale):
        Section(.versionOld) {
          Label(tailscale.version, systemImage: .imageStatusError)
            .foregroundStyle(Color.HACK_showColorInMenus, Color.statusError)
        }
      case .none:
        Section(.version) {
          Label(.noValue, systemImage: .imageStatusUnknown)
        }
      }
      Section(.tailnet) {
        Label(tailscale?.magicDNSSuffix ?? .noValue,
              systemImage: .imageSafari)
        Label(tailscale?.currentTailnet?.name ?? .noValue,
              systemImage: .imageNetwork)
      }
      Section(.account) {
        Label(user?.displayName ?? .noValue, systemImage: .imagePerson)
        Label(user?.loginName ?? .noValue,   systemImage: .imagePasswords)
      }
      Section(.magicDNS) {
        switch (tailscale?.currentTailnet?.magicDNSEnabled) {
        case .some(let magicDNSEnabled) where magicDNSEnabled == true:
          Label(.enabled, systemImage: .imageStatusOnline)
            .foregroundStyle(Color.statusOnline, Color.HACK_showColorInMenus)
        case .some(_):
          Label(.disabled, systemImage: .imageStatusOffline)
            .foregroundStyle(Color.statusOffline, Color.HACK_showColorInMenus)
        case .none:
          Label(.noValue, systemImage: .imageStatusUnknown)
        }
      }
      Section(.tunneling) {
        switch (tailscale?.tunnelingEnabled) {
        case .some(let tunnelingEnabled) where tunnelingEnabled == true:
          Label(.enabled, systemImage: .imageStatusOnline)
            .foregroundStyle(Color.statusOnline, Color.HACK_showColorInMenus)
        case .some(_):
          Label(.disabled, systemImage: .imageStatusOffline)
            .foregroundStyle(Color.statusOffline, Color.HACK_showColorInMenus)
        case .none:
          Label(.noValue, systemImage: .imageStatusUnknown)
        }
      }
      Section(.nodeKey) {
        switch (tailscale?.haveNodeKey) {
        case .some(let haveNodeKey) where haveNodeKey == true:
          Label(.present, systemImage: .imageStatusOnline)
            .foregroundStyle(Color.statusOnline, Color.HACK_showColorInMenus)
        case .some(_):
          Label(.missing, systemImage: .imageStatusOffline)
            .foregroundStyle(Color.statusOffline, Color.HACK_showColorInMenus)
        case .none:
          Label(.noValue, systemImage: .imageStatusUnknown)
        }
      }
      Button(.verbSelectThisMachine, systemImage: .imageSelect) {
        self.presentation.tableSelection = self.machines.tailscale?.selfNodeID.map { [$0] } ?? []
      }
      .disabled(self.machines.tailscale?.selfNodeID == nil)
    } label: {
      switch (self.machines.tailscale?.backendState) {
      case .some(let value) where value == "Running":
        Label(value, systemImage: .imageStatusOnline)
          .foregroundStyle(Color.statusOnline, Color.HACK_showColorInMenus)
      case .some(let value) where value == "Stopped":
        Label(value, systemImage: .imageStatusOffline)
          .foregroundStyle(Color.statusOffline, Color.HACK_showColorInMenus)
      case .some(let value):
        Label(value, systemImage: .imageStatusUnknown)
          .foregroundStyle(Color.statusUnknown, Color.HACK_showColorInMenus)
      case .none:
        Label(.noData, systemImage: .imageStatusNoData)
      }
    }
    .labelStyle(.titleAndIcon)
  }
  
  private func performAsync(function: @escaping (() async throws -> Void)) {
    Task {
      do {
        try await function()
      } catch let error as CustomNSError {
        NSLog("Error: Disabling Auto Refresh: '\(error.localizedDescription)'")
        self.settings.statusTimer.automatic = false
        self.settings.machineTimer.automatic = false
        self.processError = error
      } catch let error as NSError {
        fatalError("// TODO: Change CustomNSError property to support Error")
      }
    }
  }
}
