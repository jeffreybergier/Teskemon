//
//  Created by Jeffrey Bergier on 2025/01/18.
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

internal struct MachineInfoWindow: View {
  
  @SceneStorage("MachineInfoSelectedTab") private var currentTab = 0
  @Environment(\.dismiss) private var dismiss
  
  @TableController private var controller
  @SettingsController private var settings
  @PasswordController private var passwords

  private let ids: [Machine.Identifier]
  
  internal init(ids: Set<Machine.Identifier>) {
    self.ids = ids.sorted(by: { $0.rawValue < $1.rawValue })
  }
  
  internal var body: some View {
    NavigationStack {
      TabView(selection: self.$currentTab) {
        self.machineInfo.tabItem {
          Label("Info", systemImage: "info.circle")
        }.tag(0)
        self.namesTable.tabItem {
          Label("Names", systemImage: "person")
        }.tag(1)
        self.passwordsTable.tabItem {
          Label("Passwords", systemImage: "ellipsis.rectangle")
        }.tag(2)
      }
      .frame(width: 480, height: 320)
      .navigationTitle("Machine Info")
      .padding([.top])
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done", action: self.dismiss.callAsFunction)
        }
      }
    }
  }
  
  private var machineInfo: some View {
    Text("Machine Info")
  }
  
  private var namesTable: some View {
    Table(self.ids) {
      TableColumn("Original Name") { id in
        Text(self.controller.machine(for: id).name)
          .font(.body)
      }.width(120)
      TableColumn("Custom Name") { id in
        TextField("", text: self.customNameBinding(for: id),
                    prompt: Text(self.controller.machine(for: id).name))
        .font(.headline)
      }
    }
  }
  
  private var passwordsTable: some View {
    Table(self.ids) {
      TableColumn("Name") { id in
        Text(self.settings.customNames[id] ?? self.controller.machine(for: id).name)
          .font(.body)
      }.width(120)
      TableColumn("Username") { id in
        TextField("", text: self.passwords.username(for: id))
          .font(.headline)
      }
      TableColumn("Password") { id in
        SecureField("", text: self.passwords.password(for: id))
          .font(.headline)
      }
    }
  }
  
  private func customNameBinding(for id: Machine.Identifier) -> Binding<String> {
    .init(get: { self.settings.customNames[id] ?? "" },
          set: { self.settings.customNames[id] = $0.trimmed })
  }
  
}
