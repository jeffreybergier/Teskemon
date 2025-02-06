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

internal struct MachineTable: View {
  
  @SettingsController private var settings
  
  // TODO: Not sure why these need to be manually passed in
  // I should be able to use the property wrappers directly,
  // but data was not updating
  internal let machines: MachineController.Value
  internal let services: ServiceController.Value
  internal let spinnerValue: Double
  @Binding internal var selection: Set<Machine.Identifier>
  
  internal var body: some View {
    Table(self.machines.machines,
          children: \.subnetRoutes,
          selection: self.$selection)
    {
      
      TableColumn(.online) { machine in
        TableRowOnline(isOnline: machine.activity?.isOnline)
      }.width(24)
      
      TableColumn(.kind) { machine in
        TableRowKind(kind: machine.kind)
      }.width(24)
      
      TableColumn(.relay) { machine in
        TableRowRelay(relay: machine.relay)
      }.width(ideal: 48)
      
      TableColumn(.machine) { machine in
        TableRowName(name: machine.name,
                     host: machine.host,
                     os: machine.os,
                     customName: self.settings.customNames[machine.id])
      }.width(ideal: 128)
      
      TableColumn(.activity) { machine in
        TableRowActivity(activity: machine.activity)
      }.width(ideal: 96)
      
      TableColumn(.ping) { machine in
        TableRowPing(status: self.services[machine.id],
                     spinnerValue: self.spinnerValue)
      }.width(24)
      
      TableColumnForEach(self.settings.services) { service in
        TableColumn(String(format: "%@ (%d)", service.name, service.port)) { machine in
          TableRowStatus(machine: machine,
                         service: service,
                         status: self.services[machine.id, service],
                         spinnerValue: self.spinnerValue)
        }.width(36)
      }
    }
  }
}

internal struct TableRowOnline: View {
  internal let isOnline: Bool?
  internal var body: some View {
    switch self.isOnline {
    case .none:
      EmptyView()
    case .some(true):
      Image(systemName: .imageStatusOnline)
        .foregroundStyle(Color(nsColor: .systemGreen).gradient)
    case .some(false):
      Image(systemName: .imageStatusOffline)
        .foregroundStyle(Color(nsColor: .systemRed).gradient)
    }
  }
}

internal struct TableRowKind: View {
  
  internal let kind: Machine.Kind
  
  internal var body: some View {
    Image(systemName: self.systemImage)
      .font(.headline)
      .help(self.help)
  }
  
  private var help: LocalizedStringKey {
    switch self.kind {
    case .meHost:       return .helpNodeMe
    case .remoteHost:   return .helpNodeRemote
    case .meSubnet:     return .helpNodeSubnetMe
    case .remoteSubnet: return .helpNodeSubnetRemote
    }
  }
  
  private var systemImage: String {
    switch self.kind {
    case .meHost:
      return .imageNodeMe
    case .remoteHost:
      return .imageNodeRemote
    case .meSubnet:
      return .imageNodeMeSubnet
    case .remoteSubnet:
      return .imageNodeRemoteSubnet
    }
  }
}

internal struct TableRowRelay: View {
  
  internal let relay: Machine.Relay
  
  internal var body: some View {
    Text(self.relay.displayName)
      .font(.subheadline)
      .help(self.relay.displayName)
  }
}

internal struct TableRowName: View {
  
  internal let name: String
  internal let host: String
  internal let os: String?
  internal let customName: String?
  
  internal var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment:.firstTextBaseline) {
        Text(self.customName ?? self.name).font(.headline)
        if let os {
          Text(os).font(.subheadline)
        }
      }
      Text(self.host).font(.subheadline)
    }
  }
}

internal struct TableRowActivity: View {
  
  private static let byteF = ByteCountFormatter()
  
  // TODO: Move this to MachineWindow
  @Environment(\.appearsActive) private var sceneAppearsActive
  @TimerProperty(identifier: "MachineTable",
                 interval: 1.0)
                 private var activityTimer

  internal let activity: Machine.Activity?
  
  internal var body: some View {
    HStack(alignment: .center) {
      self.indicator
      if let activity {
        HStack(spacing: 4) {
          Image(systemName: .imageActivityUpDown)
            .font(.headline)
          VStack(alignment: .leading, spacing: 0) {
            Text(type(of: self).byteF.string(fromByteCount: activity.txBytes))
            Text(type(of: self).byteF.string(fromByteCount: activity.rxBytes))
          }.font(.subheadline)
        }
      }
    }
    .onChange(of: self.sceneAppearsActive, initial: true, self.manageTimer)
    .onChange(of: self.activity?.isActive, initial: true, self.manageTimer)
  }
  
  private func manageTimer<T>(_ oldValue: T, newValue: T) {
    if self.sceneAppearsActive, (self.activity?.isActive ?? false) {
      self.activityTimer.retain()
    } else {
      self.activityTimer.release()
    }
  }
  
  @ViewBuilder private var indicator: some View {
    switch activity?.isActive {
    case .some(true):
      Image(systemName: .imageActivityActive,
            variableValue: self.activityTimer.percentage(of: 10))
        .font(.headline)
    case .some(false):
      Image(systemName: .imageActivityInactive)
        .font(.headline)
    case .none:
      Image(systemName: .imageActivityUnknown)
        .font(.headline)
        .foregroundStyle(Color(nsColor: .systemGray).gradient)
    }
  }
}

internal struct TableRowPing: View {
  
  internal let status: Service.Status
  internal let spinnerValue: Double
  
  internal var body: some View {
    Label {
      Text(self.help)
    } icon: {
      switch self.status {
      case .online:
        Image(systemName: .imageStatusOnline)
          .foregroundStyle(Color(nsColor: .systemGreen).gradient)
      case .offline:
        Image(systemName: .imageStatusOffline)
          .foregroundStyle(Color(nsColor: .systemRed).gradient)
      case .error:
        Image(systemName: .imageStatusError)
          .foregroundStyle(Color(nsColor: .systemYellow).gradient)
      case .unknown:
        Image(systemName: .imageStatusUnknown)
          .foregroundStyle(Color(nsColor: .systemGray).gradient)
      case .processing:
        Image(systemName: .imageStatusProcessing,
              variableValue: self.spinnerValue)
      }
    }
    .labelStyle(.iconOnly)
    .help(self.help)
  }
  
  private var help: LocalizedStringKey {
    switch self.status {
    case .unknown:    return .helpPingUnknown
    case .error:      return .helpPingError
    case .online:     return .helpPingOnline
    case .offline:    return .helpPingOffline
    case .processing: return .helpPingProcessing
    }
  }
}

internal struct TableRowStatus: View {
  
  @PasswordController private var passwords
  
  internal let machine: Machine
  internal let service: Service
  internal let status: Service.Status
  internal let spinnerValue: Double
  
  internal var body: some View {
    Button {
      let password = self.passwords[self.machine]
      guard let url = self.machine.url(for: self.service,
                                       username: password.user_account,
                                       password: password.user_password)
      else { assertionFailure("URL was NIL"); return }
      NSWorkspace.shared.open(url)
    } label: {
      Label {
        Text(.open)
      } icon: {
        self.image.foregroundStyle(self.color)
      }
    }
    .labelStyle(.iconOnly)
    .buttonStyle(.bordered)
    .help(self.help)
  }
  
  private var image: Image {
    switch self.status {
    case .unknown: Image(systemName: .imageStatusUnknown)
    case .error:   Image(systemName: .imageStatusError)
    case .online:  Image(systemName: .imageStatusOnline)
    case .offline: Image(systemName: .imageStatusOffline)
    case .processing:
      Image(systemName: .imageStatusProcessing,
            variableValue: self.spinnerValue)
    }
  }
  
  private var color: AnyGradient {
    switch self.status {
    case .unknown:    return Color.statusUnknown
    case .error:      return Color.statusError
    case .online:     return Color.statusOnline
    case .offline:    return Color.statusOffline
    case .processing: return Color.statusProcessing
    }
  }
  
  private var help: LocalizedStringKey {
    switch self.status {
    case .unknown:    return .helpNetcatUnknown
    case .error:      return .helpNetcatError
    case .online:     return .helpNetcatOnline
    case .offline:    return .helpNetcatOffline
    case .processing: return .helpNetcatProcessing
    }
  }
}
