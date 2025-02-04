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
        let machine = self.machines[id]
        let password = self.passwords[machine]
        TextField("", text: self.passwords.bind(machine).user_account)
          .textFieldStyle(.roundedBorder)
          .disabled(password.status != .isEditing)
      }
      TableColumn(.password) { id in
        let machine = self.machines[id]
        let password = self.passwords[machine]
        TextField("", text: self.passwords.bind(machine).user_password)
          .textFieldStyle(.roundedBorder)
          .disabled(password.status != .isEditing)
      }
      TableColumn("Action") { id in
        HStack {
          let machine = self.machines[id]
          let password = self.passwords[machine]
          switch (password.status) {
          case .isViewing:
            HStack(spacing: 4) {
              Button {
                self.passwords[machine].status = .isEditing
              } label: {
                switch password.inKeychain {
                case true : Label(.edit, systemImage: .imageEdit)
                case false: Label(.add,  systemImage: .imageAdd)
                }
              }
              Button {
                self.passwords.deletePassword(for: machine)
              } label: {
                Label(.delete, systemImage: .imageDelete)
              }
            }
          case .isEditing:
            HStack(spacing: 4) {
              Button {
                self.passwords.resetPassword(for: machine)
              } label: {
                Label(.reset, systemImage: .imageReset)
              }
              Button {
                self.passwords.savePassword(for: machine)
              } label: {
                Label(.save, systemImage: .imageSave)
              }
            }
          case .keychainError(let error):
            Button {
              // TODO: Make this show an error
              NSLog(error.localizedDescription)
            } label: {
              Label(.error, systemImage: .imageError)
            }
          case .error(let error):
            Button {
              // TODO: Make this show an error
              NSLog(error.localizedDescription)
            } label: {
              Label(.error, systemImage: .imageError)
            }
          }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
      }
    }
  }
  
  private func customNameBinding(for id: Machine.Identifier) -> Binding<String> {
    .init(get: { self.settings.customNames[id] ?? "" },
          set: { self.settings.customNames[id] = $0.trimmed })
  }
  
}
