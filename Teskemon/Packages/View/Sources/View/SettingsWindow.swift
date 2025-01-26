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
  
  @SettingsController private var settings
  
  public init() { }
  
  public var body: some View {
    TabView(selection: self.$settings.currentTab) {
      self.general.tabItem {
        Label.settingsGeneral
      }.tag(SettingsTab.general)
      self.services.tabItem {
        Label.settingsServices
      }.tag(SettingsTab.services)
    }
  }
  
  private var general: some View {
    Form {
      Section(header: Text("Tailscale").font(.headline),
              footer: Text(self.settings.executable.stringValue).font(.caption))
      {
        Picker("Location", selection: self.$settings.executable.option) {
          Text("Command Line").tag(SettingsExecutable.Options.cli)
          Text("App Store").tag(SettingsExecutable.Options.app)
          Text("Custom").tag(SettingsExecutable.Options.custom)
        }
        if self.settings.executable.option == .custom {
          TextField("Path", text: self.$settings.executable.rawValue)
        }
      }
      Divider().padding([.bottom], 6)
      Section(header: Text("Machine Refresh").font(.headline)) {
        Toggle("Automatic", isOn: self.$settings.machineTimer.automatic)
        TextField("Interval",
                  text: self.$settings.machineTimer.interval.map(get: { $0.description },
                                                                 set: { Int($0) ?? -1 }))
      }
      Divider().padding([.bottom], 6)
      Section(header: Text("Service Refresh").font(.headline)) {
        Toggle("Automatic", isOn: self.$settings.statusTimer.automatic)
        TextField("Interval",
                  text: self.$settings.statusTimer.interval.map(get: { $0.description },
                                                                set: { Int($0) ?? -1 }))
      }
      Divider().padding([.bottom], 6)
      Section(header: Text("Netcat").font(.headline)) {
        TextField("Timeout",
                  text: self.$settings.timeout.map(get: { $0.description },
                                                   set: { Int($0) ?? -1 }))
        TextField("Batch Size",
                  text: self.$settings.batchSize.map(get: { $0.description },
                                                     set: { Int($0) ?? -1 }))
      }
    }
    .padding()
    .frame(width: 320)
  }
  
  private var services: some View {
    ZStack(alignment: .bottomTrailing) {
      Table(self.$settings.services) {
        TableColumn("Name") { service in
          TextField("", text: service.name)
        }
        TableColumn("Protocol") { service in
          TextField("", text: service.scheme)
        }.width(64)
        TableColumn("Port") { service in
          TextField("", text: service.port.map(get: { $0.description },
                                               set: { Int($0) ?? -1 }))
        }.width(64)
        TableColumn("") { service in
          Button("Delete", systemImage: "x.circle") {
            self.settings.delete(service: service.wrappedValue)
          }
          .labelStyle(.iconOnly)
        }.width(16)
      }
      .textFieldStyle(.roundedBorder)
      .safeAreaInset(edge: .bottom) {
        HStack {
          Spacer()
          Button("Reset", systemImage: "arrow.uturn.left") {
            self.settings.services = Service.default
          }
          Button("Add", systemImage: "plus") {
            self.settings.services.append(.init())
          }
        }.padding([.bottom, .trailing])
      }
    }
    .frame(width: 480, height: 320)
  }
}
