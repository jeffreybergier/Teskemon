//
//  Created by Jeffrey Bergier on 2025/01/18.
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

internal struct InfoSheet: View {
  
  @Environment(\.dismiss) private var dismiss
  
  @MachineController  private var machines
  @SettingsController private var settings
  @PasswordController private var passwords

  @State private var currentTab: Int
  private let selection: [Machine.Identifier]
  
  internal init(_ input: PresentationInfoPanelInput) {
    _currentTab = .init(initialValue: input.currentTab)
    selection = input.selection
  }
  
  internal var body: some View {
    NavigationStack {
      TabView(selection: self.$currentTab) {
        self.machineInfo.tabItem {
          Label(.info, systemImage: .imageInfo)
        }.tag(0)
        self.namesTable.tabItem {
          Label(.names, systemImage: .imagePerson)
        }.tag(1)
        self.passwordsTable.tabItem {
          Label(.passwords, systemImage: .imagePasswords)
        }.tag(2)
      }
      .frame(width: 480, height: 320)
      .navigationTitle(.machineInfo)
      .padding([.top])
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(.done, action: self.dismiss.callAsFunction)
        }
      }
    }
  }
  
  private var machineInfo: some View {
    // TODO: Add machine info view
    Text(.machineInfo)
  }
  
  private var namesTable: some View {
    Table(self.selection) {
      TableColumn(.nameOriginal) { id in
        Text(self.machines[id].name)
          .font(.body)
      }.width(120)
      TableColumn(.nameCustom) { id in
        TextField("", text: self.customNameBinding(for: id),
                    prompt: Text(self.machines[id].name))
        .font(.headline)
      }
    }
  }
  
  private var passwordsTable: some View {
    Table(self.selection) {
      TableColumn(.name) { id in
        Text(self.settings.customNames[id] ?? self.machines[id].name)
          .font(.body)
      }.width(120)
      TableColumn(.username) { id in
        switch (self.passwords[id].status) {
        case .new, .saved:
          Text(self.passwords[id].account.trimmed ?? "–")
        case .newModified, .savedModified:
          TextField("", text: self.$passwords[id].account)
        case .error(let error):
          Text(String(describing: error))
        }
      }
      TableColumn(.password) { id in
        let password = self.passwords[id]
        switch (password.status) {
        case .new, .saved:
          Text(self.passwords[id].password.trimmed ?? "–")
        case .newModified, .savedModified:
          TextField("", text: self.$passwords[id].password)
        case .error(let error):
          Text(String(describing: error))
        }
      }
      TableColumn("Action") { id in
        let password = self.passwords[id]
        switch (password.status) {
        case .new:
          Button("Add") {
            self.passwords[id].status = .newModified
          }
        case .saved:
          Button("Update") {
            self.passwords[id].status = .savedModified
          }
        case .newModified, .savedModified:
          Button("Save") {
            _passwords.save(id: id)
          }
        case .error:
          EmptyView()
        }
      }
    }
    .onAppear {
      _passwords.prefetch(ids: self.selection)
    }
  }
  
  private func customNameBinding(for id: Machine.Identifier) -> Binding<String> {
    .init(get: { self.settings.customNames[id] ?? "" },
          set: { self.settings.customNames[id] = $0.trimmed })
  }
  
}
