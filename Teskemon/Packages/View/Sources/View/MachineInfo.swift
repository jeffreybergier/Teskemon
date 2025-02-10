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

internal struct MachineInfo: View {
  
  @PresentationController private var presentation
  
  private let selection: [Machine.Identifier]
  
  internal init(selection: Set<Machine.Identifier>) {
    self.selection = selection.sorted { $0.rawValue < $1.rawValue }
  }
  
  internal var body: some View {
    NavigationStack {
      Group {
        switch self.presentation.infoPanel.currentTab {
        case .info:      MachineInfoOverview (selection: self.selection)
        case .names:     MachineInfoNames    (selection: self.selection)
        case .passwords: MachineInfoPasswords(selection: self.selection)
        }
      }
      .safeAreaInset(edge: .top, alignment: .center, spacing: 0) {
        HStack {
          Spacer()
          Picker("", selection: self.$presentation.infoPanel.currentTab) {
            Text(.information).tag(Presentation.InfoPanelTab.info)
            Text(.names      ).tag(Presentation.InfoPanelTab.names)
            Text(.passwords  ).tag(Presentation.InfoPanelTab.passwords)
          }
          .padding(self.pickerPadding)
          .frame(width: SettingsWindow.widthLarge/2)
          .pickerStyle(.segmented)
          Spacer()
        }
        .background(self.pickerBackground)
      }
      .navigationTitle(.machineInfo)
      .navigationSubtitle(.selected(self.selection.count))
      .frame(width: SettingsWindow.widthLarge, height: SettingsWindow.height)
      .animation(.default, value: self.presentation.infoPanel.currentTab)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(.done) {
            self.presentation.infoPanel.isPresented = false
          }
        }
      }
    }
  }
  
  @ViewBuilder private var pickerBackground: some View {
    switch self.presentation.infoPanel.currentTab {
    case .info:              EmptyView()
    case .names, .passwords: Color.white.opacity(0.0).background(.bar)
    }
  }
  
  private var pickerPadding: EdgeInsets {
    switch self.presentation.infoPanel.currentTab {
    case .info:              return EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)
    case .names, .passwords: return EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0)
    }
  }
}

internal struct MachineInfoOverview: View {
  
  @MachineController      private var machines
  @SettingsController     private var settings
  @PresentationController private var presentation
  
  internal let selection: [Machine.Identifier]
  
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
        let user = self.machines.users[machine.userID]
        Section(self.computedName(for: id),
                isExpanded: self.infoSectionExpanded(for: id))
        {
          if self.isReal(machine.kind) {
            VStack {
              LabeledContent(.id,            value: self.string(for: machine.id.rawValue))
              LabeledContent(.name,          value: self.string(for: machine.name))
              LabeledContent(.nameCustom,    value: self.string(for: self.settings.customNames[id]))
              LabeledContent(.opSystem,      value: self.string(for: machine.os))
              LabeledContent(.host,          value: self.string(for: machine.host))
              LabeledContent(.ip,            value: self.string(for: machine.ips))
              LabeledContent(.relay,         value: self.string(for: machine.relay))
              LabeledContent(.relationship,  value: self.string(for: machine.kind))
              LabeledContent(.subnetRoutes,  value: self.string(for: machine.subnetRoutes))
            }
            VStack {
              LabeledContent(.publicKey,     value: self.string(for: machine.nodeInfo?.publicKey))
              LabeledContent(.keyExpiry,     value: self.string(for: machine.nodeInfo?.keyExpiry))
              LabeledContent(.created,       value: self.string(for: machine.nodeInfo?.created))
              LabeledContent(.lastWrite,     value: self.string(for: machine.nodeInfo?.lastWrite))
              LabeledContent(.lastHandshake, value: self.string(for: machine.nodeInfo?.lastHandshake))
            }
            VStack {
              LabeledContent(.inNetworkMap,  value: self.string(for: machine.nodeInfo?.inNetworkMap))
              LabeledContent(.inMagicSock,   value: self.string(for: machine.nodeInfo?.inMagicSock))
              LabeledContent(.inEngine,      value: self.string(for: machine.nodeInfo?.inEngine))
            }
            VStack {
              LabeledContent(.userID,        value: self.string(for: user?.id.rawValue))
              LabeledContent(.username,      value: self.string(for: user?.loginName))
              LabeledContent(.displayName,   value: self.string(for: user?.displayName))
              LabeledContent(.roles,         value: self.string(for: user?.roles))
              LabeledContent(.profPic) {
                self.image(for: user?.profilePicURL)
              }
            }
          } else {
            VStack {
              LabeledContent(.ip,            value: self.string(for: machine.ips))
              LabeledContent(.nameCustom,    value: self.string(for: self.settings.customNames[id]))
              LabeledContent(.relay,         value: self.string(for: machine.relay))
              LabeledContent(.relationship,  value: self.string(for: machine.kind))
            }
          }
        }
      }
    }
    .formStyle(.grouped)
  }
  
  private func computedName(for id: Machine.Identifier) -> String {
    (self.settings.customNames[id] ?? self.machines[id].name).trimmed ?? .noValue
  }
  
  private func isReal(_ kind: Machine.Kind) -> Bool {
    switch kind {
    case .meHost, .remoteHost:               return true
    case .unknown, .meSubnet, .remoteSubnet: return false
    }
  }
  
  private func string(for kind: Machine.Kind) -> LocalizedStringKey {
    switch kind {
    case .unknown:      return .noValue
    case .meHost:       return .helpNodeMe
    case .remoteHost:   return .helpNodeRemote
    case .meSubnet:     return .helpNodeSubnetMe
    case .remoteSubnet: return .helpNodeSubnetRemote
    }
  }
  
  private func string(for relay: Machine.Relay) -> LocalizedStringKey {
    switch relay {
    case .unknown:                      return .noValue
    case .relay(let name):              return .relayTailscale(name)
    case .route(id: _, name: let name): return .relayRoute(name)
    }
  }
  
  private func string(for strings: [String]?) -> String {
    return strings?.reduce("") {
      $0.isEmpty ? $1 : $0 + ", " + $1
    }
    .trimmed ?? .noValue
  }
  
  private func string<Raw: RawRepresentable>(for subnets: [Raw]?) -> String
                where Raw.RawValue == String
  {
    return subnets?.reduce("") {
      $0.isEmpty ? $1.rawValue : $0 + ", " + $1.rawValue
    }
    .trimmed ?? .noValue
  }
  
  private func string(for date: Date?) -> String {
    return date.map { df.string(from: $0) } ?? .noValue
  }
  
  private func string(for string: String?) -> String {
    return string?.trimmed ?? .noValue
  }
  
  private func string(for bool: Bool?) -> LocalizedStringKey {
    return bool.map { $0 ? .yes : .no } ?? .noValue
  }
  
  private func string(for number: Int?) -> String {
    return number.map { $0.description } ?? .noValue
  }
  
  @ViewBuilder private func image(for string: String?) -> some View {
    if let string, let url = URL(string: string) {
      VStack(alignment: .trailing) {
        AsyncImage(url: url, scale: 1) { image in
          image
            .resizable()
            .scaledToFit()
            .frame(width: 128)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } placeholder: {
          Image(systemName: .imageStatusError)
            .foregroundStyle(Color.statusError)
        }
        Button(url.absoluteString) {
          NSWorkspace.shared.open(url)
        }
        .buttonStyle(.link)
      }
    } else {
      Text(.noValue)
    }
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
    .alert(error: self.$passwordError)
  }
}

fileprivate func LabeledContent(_ title: LocalizedStringKey,
                                value: LocalizedStringKey)
                                -> LabeledContent<Text, Text>
{
  return LabeledContent(title) { Text(value) }
}

private let df: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateStyle = .medium
  formatter.timeStyle = .medium
  return formatter
}()
