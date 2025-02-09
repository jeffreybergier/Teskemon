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

// TODO: Refactor this into 4 views and use Picker instead of TabView
internal struct MachineInfo: View {
  
  @PresentationController private var presentation
  
  private let selection: [Machine.Identifier]
  
  internal init(selection: Set<Machine.Identifier>) {
    self.selection = selection.sorted { $0.rawValue < $1.rawValue }
  }
  
  internal var body: some View {
    NavigationStack {
      VStack {
        // TODO: Consider moving this into .safeAreaInset(edge: .top)
        Picker("", selection: self.$presentation.infoPanel.currentTab) {
          Text(.information)
            .tag(PresentationInfoPanelTab.info)
          Text(.names)
            .tag(PresentationInfoPanelTab.names)
          Text(.passwords)
            .tag(PresentationInfoPanelTab.passwords)
        }
        .frame(width: SettingsWindow.widthLarge/2)
        .padding([.top], 8)
        Group {
          switch self.presentation.infoPanel.currentTab {
          case .info:      MachineInfoOverview(selection: self.selection)
          case .names:     MachineInfoNames(selection: self.selection)
          case .passwords: MachineInfoPasswords(selection: self.selection)
          }
        }
      }
      .pickerStyle(.segmented)
      .navigationTitle(.machineInfo)
      .navigationSubtitle(.selected(self.selection.count))
      .frame(width: SettingsWindow.widthLarge, height: SettingsWindow.height)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(.done) {
            self.presentation.infoPanel.isPresented = false
          }
        }
      }
    }
  }
}

internal struct MachineInfoOverview: View {
  
  @MachineController      private var machines
  @PresentationController private var presentation
  
  internal let selection: [Machine.Identifier]
    
  /*
   public var id: Identifier = .init(rawValue: "")
   public var name: String   = ""
   public var host: String   = ""
   public var os: String     = ""
   public var kind: Kind     = .unknown
   public var relay: Relay   = .unknown
   public var activity: Activity? = nil
   public var nodeInfo: NodeInfo? = nil
   public var subnetRoutes: [Machine]? = nil
   
   public var publicKey:  String = ""
   public var keyExpiry:  Date?  = nil
   public var isExitNode: Bool   = false
   public var userID:     Int    = -1
   // Network
   public var tailscaleIPs: [Address] = []
   
   // Timestamps
   public var created:       Date? = nil
   public var lastWrite:     Date? = nil
   public var lastHandshake: Date? = nil
   // Status
   public var inNetworkMap: Bool = false
   public var inMagicSock:  Bool = false
   public var inEngine:     Bool = false
   */
  
  private func infoSectionExpanded(for id: Machine.Identifier) -> Binding<Bool> {
    let shouldShowByDefault = self.selection.count <= 7
    return Binding {
      self.presentation.infoPanel.isExpanded[id] ?? shouldShowByDefault
    } set: {
      self.presentation.infoPanel.isExpanded[id] = $0 != shouldShowByDefault ? $0 : nil
    }
  }
  
  internal var body: some View {
    Form {
      ForEach(self.selection) { id in
        let machine = self.machines[id]
        Section(machine.name, isExpanded: self.infoSectionExpanded(for: id)) {
          LabeledContent("ID",    value: machine.id.rawValue.trimmed ?? .noValue)
          LabeledContent("Name",  value: machine.name.trimmed ?? .noValue)
          LabeledContent("Host",  value: machine.host.trimmed ?? .noValue)
          LabeledContent("OS",    value: machine.os.trimmed ?? .noValue)
          LabeledContent("Kind",  value: String(describing:machine.kind))
          LabeledContent("Relationship", value: String(describing:machine.relay))
          LabeledContent("Public Key", value: machine.nodeInfo?.publicKey.trimmed ?? .noValue)
          LabeledContent("Subnet Routes", value: machine.subnetRoutes.reduce("", { $0 + $1.rawValue + ", " }))
        }
      }
    }
    .formStyle(.grouped)
  }
}

internal struct MachineInfoNames: View {
  
  @MachineController      private var machines
  @SettingsController     private var settings
  @PresentationController private var presentation
  
  internal let selection: [Machine.Identifier]
  
  internal var body: some View {
    Table(self.selection) {
      TableColumn(.nameOriginal) { id in
        Text(self.machines[id].name)
          .font(.body)
      }.width(120)
      TableColumn(.nameCustom) { id in
        TextField("", text: self.customNameBinding(for: id),
                    prompt: Text(self.machines[id].name))
        .textFieldStyle(.roundedBorder)
      }
    }
    .padding([.top], 4)
  }
  
  private func customNameBinding(for id: Machine.Identifier) -> Binding<String> {
    .init(get: { self.settings.customNames[id] ?? "" },
          set: { self.settings.customNames[id] = $0.trimmed })
  }
  
}

internal struct MachineInfoPasswords: View {
  
  @MachineController      private var machines
  @SettingsController     private var settings
  @PasswordEditController private var passwords
  @PresentationController private var presentation
  
  @State private var passwordError: CustomNSError?
  
  internal let selection: [Machine.Identifier]
  
  internal var body: some View {
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
        SecureField("", text: self.passwords.bind(machine).user_password)
          .textFieldStyle(.roundedBorder)
          .disabled(password.status != .isEditing)
      }
      TableColumn(.actions) { id in
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
                Label(.delete, systemImage: .imageDeleteX)
              }
              .disabled(!password.inKeychain)
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
          case .error(let error):
            Button {
              NSLog(error.localizedDescription)
              self.passwordError = error
              self.passwords.resetPassword(for: machine)
            } label: {
              Label(.error, systemImage: .imageError)
            }
            Button {
              self.passwords.deletePassword(for: machine)
            } label: {
              Label(.delete, systemImage: .imageDeleteX)
            }
            .disabled(!password.inKeychain)
          }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
      }
      .width(64)
    }
    .padding([.top], 4)
    .alert(error: self.$passwordError)
  }
}


