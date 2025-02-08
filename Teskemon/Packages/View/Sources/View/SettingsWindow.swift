//
//  Created by Jeffrey Bergier on 2025/01/16.
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

public struct SettingsWindow: View {
  
  static let width:  Double = 480
  static let height: Double = 320
  
  @SettingsController private var settings
  
  public init() { }
  
  public var body: some View {
    TabView(selection: self.$settings.currentTab) {
      self.tailscale.tabItem {
        Label(.tailscale, systemImage: .imageSettings)
      }
      .tag(SettingsTab.tailscale)
      self.services.tabItem {
        Label(.services, systemImage: .imageServices)
      }
      .tag(SettingsTab.services)
      self.scanning.tabItem {
        Label(.scanning, systemImage: .imageScanning)
      }
      .tag(SettingsTab.scanning)
    }
  }
  
  private var tailscale: some View {
    Form {
      Section(header: Text(.tailscale).font(.headline),
              footer: Text(self.settings.executable.stringValue).font(.caption))
      {
        Picker(.location, selection: self.$settings.executable.option) {
          Text(.commandLine).tag(SettingsExecutable.Options.cli)
          Text(.appStore).tag(SettingsExecutable.Options.app)
          Text(.custom).tag(SettingsExecutable.Options.custom)
        }
        if self.settings.executable.option == .custom {
          TextField(.path, text: self.$settings.executable.rawValue)
        }
      }
      Divider().padding([.bottom], 6)
      Section(header: Text(.machineRefresh).font(.headline)) {
        Toggle(.automatic, isOn: self.$settings.machineTimer.automatic)
        TextField(.interval,
                  text: self.$settings.machineTimer.interval.map(get: { $0.description },
                                                                 set: { TimeInterval($0) ?? 0 }))
      }
      Divider().padding([.bottom], 6)
      Section(header: Text(.serviceRefresh).font(.headline)) {
        Toggle(.automatic, isOn: self.$settings.statusTimer.automatic)
        TextField(.interval,
                  text: self.$settings.statusTimer.interval.map(get: { $0.description },
                                                                set: { TimeInterval($0) ?? 0 }))
      }
    }
    .padding()
    .frame(width: SettingsWindow.width)
  }
  
  private var services: some View {
    ZStack(alignment: .bottomTrailing) {
      // TODO: Make this table sortable
      Table(self.$settings.services) {
        TableColumn(.name) { service in
          TextField("", text: service.name)
        }
        TableColumn(.scheme) { service in
          TextField("", text: service.scheme)
        }.width(64)
        TableColumn(.port) { service in
          TextField("", text: service.port.map(get: { $0.description },
                                               set: { Int($0) ?? -1 }))
        }.width(64)
        TableColumn("") { service in
          Button(.delete, systemImage: .imageDeleteXCircle) {
            self.settings.delete(service: service.wrappedValue)
          }
          .labelStyle(.iconOnly)
        }.width(16)
      }
      .textFieldStyle(.roundedBorder)
      .safeAreaInset(edge: .bottom) {
        HStack {
          Spacer()
          Button(.reset, systemImage: .imageReset) {
            self.settings.services = Service.default
          }
          Button(.add, systemImage: .imageAdd) {
            self.settings.services.append(.init())
          }
        }.padding([.bottom, .trailing])
      }
    }
    .frame(width: SettingsWindow.width, height: SettingsWindow.height)
  }
  
  private var scanning: some View {
    Form {
      Section(header: Text(.netcat).font(.headline)) {
        TextField(.timeout,
                  text: self.$settings.scanning.netcatTimeout.map(get: { $0.description },
                                                                  set: { Int($0) ?? -1 }))
        TextField(.batchSize,
                  text: self.$settings.scanning.batchSize.map(get: { $0.description },
                                                              set: { Int($0) ?? -1 }))
      }
      Section(header: Text(.ping).font(.headline)) {
        TextField(.count,
                  text: self.$settings.scanning.pingCount.map(get: { $0.description },
                                                              set: { Int($0) ?? -1 }))
        TextField(.lossThreshold,
                  text: self.$settings.scanning.pingLoss.map(get: { $0.description },
                                                             set: { Double($0) ?? -1 }))
      }
    }
    .padding()
    .frame(width: SettingsWindow.width)
  }
}
