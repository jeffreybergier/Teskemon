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
  @PasswordController private var passwords
  
  // TODO: Not sure why these need to be bindings
  // I should be able to directly use
  // @PresentationController and @StatusController
  // They should also allowed to be @State and not @Binding
  @Binding internal var table: TableController.Value
  @Binding internal var status: StatusController.Value
  @Binding internal var selection: Set<Machine.Identifier>
  
  internal var body: some View {
    Table(self.table.machines,
          children: \.subnetRoutes,
          selection: self.$selection)
    {
      
      TableColumn("Online") { machine in
        TableRowOnline(isOnline: machine.activity?.isOnline)
      }.width(36)
      
      TableColumn("Kind") { machine in
        TableRowKind(kind: machine.kind)
      }.width(24)
      
      TableColumn("Relay") { machine in
        TableRowRelay(relay: machine.relay)
      }.width(ideal: 48)
      
      TableColumn("Machine") { machine in
        TableRowName(name: machine.name,
                     url: machine.url,
                     os: machine.os,
                     customName: self.settings.customNames[machine.id])
      }.width(ideal: 128)
      
      TableColumn("Activity") { machine in
        TableRowActivity(activity: machine.activity)
      }.width(ideal: 96)
      
      TableColumnForEach(self.settings.services) { service in
        TableColumn(service.name + String(format: " (%d)", service.port)) { machine in
          TableRowStatus(status: self.status[machine.id, service],
                         url:    self.table.url(for: service,
                                                on: machine.id,
                                                username: self.passwords[.username, machine.id],
                                                password: self.passwords[.password, machine.id]))
        }.width(36)
      }
    }
    .safeAreaInset(edge: .bottom) {
      if let tailscale = self.table.tailscale {
        TailscaleOverlay(tailscale: tailscale)
      }
    }
  }
}

internal struct TableRowOnline: View {
  internal let isOnline: Bool?
  internal var body: some View {
    switch self.isOnline {
    case .none:
      Image(systemName: "circle.dotted")
        .foregroundStyle(Color(nsColor: .systemGray))
    case .some(true):
      Image(systemName: "circle.fill")
        .foregroundStyle(Color(nsColor: .systemGreen).gradient)
    case .some(false):
      Image(systemName: "stop.fill")
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
  
  private var help: String {
    switch self.kind {
    case .meHost:
      return "This Node"
    case .remoteHost:
      return "Peer Node"
    case .meSubnet:
      return "Route Advertised by this Node"
    case .remoteSubnet:
      return "Route Advertised by Peer Node"
    }
  }
  
  private var systemImage: String {
    switch self.kind {
    case .meHost:
      return "person.crop.rectangle"
    case .remoteHost:
      return "rectangle"
    case .meSubnet:
      return "person.crop.rectangle.stack"
    case .remoteSubnet:
      return "rectangle.stack"
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
  internal let url: String
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
      Text(self.url).font(.subheadline)
    }
  }
}

internal struct TableRowActivity: View {
  
  private let byteF = ByteCountFormatter()
  
  internal let activity: Machine.Activity?
  internal var body: some View {
    HStack(alignment: .center) {
      self.indicator
      if let activity {
        HStack(spacing: 4) {
          Image(systemName: "chevron.up.chevron.down")
            .font(.headline)
          VStack(alignment: .leading, spacing: 0) {
            Text(byteF.string(fromByteCount: activity.txBytes))
            Text(byteF.string(fromByteCount: activity.rxBytes))
          }.font(.subheadline)
        }
      }
    }
  }
  
  @ViewBuilder private var indicator: some View {
    if let activity {
      // TODO: Add animations for progress indicator
      Image(systemName: activity.isActive ? "progress.indicator" : "pause.circle")
        .font(.headline)
    } else {
      Image(systemName: "circle.dotted")
        .font(.headline)
        .foregroundStyle(Color(nsColor: .systemGray).gradient)
    }
  }
}

internal struct TableRowStatus: View {
  
  internal let status: Service.Status
  internal let url: URL
  
  internal var body: some View {
    Button {
      NSWorkspace.shared.open(self.url)
    } label: {
      Label {
        Text("Open")
      } icon: {
        switch self.status {
        case .online:
          Image(systemName: "circle.fill")
            .foregroundStyle(Color(nsColor: .systemGreen).gradient)
        case .offline:
          Image(systemName: "stop.fill")
            .foregroundStyle(Color(nsColor: .systemRed).gradient)
        case .error:
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(Color(nsColor: .systemYellow).gradient)
        case .unknown:
          Image(systemName: "questionmark.diamond.fill")
            .foregroundStyle(Color(nsColor: .systemGray).gradient)
        case .processing:
          Image(systemName: "progress.indicator")
        }
      }
      .labelStyle(.iconOnly)
    }
    .buttonStyle(.bordered)
    .help(self.help)
  }
  
  private var help: String {
    switch self.status {
    case .unknown: return "Netcat: Not yet scanned"
    case .error: return "Netcat: Timeout"
    case .online: return "Netcat: Port listening"
    case .offline: return "Netcat: Port not listening"
    case .processing: return "Netcat: Scanning"
    }
  }
}

// TODO: Polish up this info view
internal struct TailscaleOverlay: View {
  
  internal let tailscale: Tailscale
  
  internal var body: some View {
    self.tailnetView
    .background(.ultraThinMaterial)
    .cornerRadius(8)
    .padding([.bottom, .leading, .trailing], 10)
  }
  
  @ViewBuilder private var tailnetView: some View {
    if let tailnet = tailscale.currentTailnet {
      VStack {
        Text("Tailscale")
          .font(.title2)
        Grid(alignment: .topLeading) {
          GridRow(alignment: .lastTextBaseline) {
            Text("User:")
              .font(.callout)
            Text(tailnet.name)
              .font(.headline)
          }
          GridRow(alignment: .lastTextBaseline) {
            Text("Domain:")
              .font(.callout)
            Text(tailnet.magicDNSSuffix)
              .font(.headline)
          }
          GridRow(alignment: .lastTextBaseline) {
            Text("Version:")
              .font(.callout)
            Text(self.tailscale.version)
              .font(.headline)
          }
          GridRow(alignment: .lastTextBaseline) {
            Text("Status:")
              .font(.callout)
            if self.tailscale.backendState == "Running" {
              Label(self.tailscale.backendState, systemImage: "circle.fill")
                .font(.headline)
                .foregroundStyle(Color(nsColor: .systemGreen).gradient)
            } else {
              Label(self.tailscale.backendState, systemImage: "stop.fill")
                .font(.headline)
                .foregroundStyle(Color(nsColor: .systemRed).gradient)
            }
          }
          GridRow(alignment: .lastTextBaseline) {
            Text("Update:")
              .font(.callout)
            if self.tailscale.versionUpToDate {
              Label("Up to Date", systemImage: "circle.fill")
                .font(.headline)
                .foregroundStyle(Color(nsColor: .systemGreen).gradient)
            } else {
              Label("Available", systemImage: "triangle.fill")
                .font(.headline)
                .foregroundStyle(Color(nsColor: .systemYellow).gradient)
            }
          }
          GridRow(alignment: .lastTextBaseline) {
            Text("Magic DNS:")
              .font(.callout)
            if tailnet.magicDNSEnabled {
              Label("Enabled", systemImage: "circle.fill")
                .font(.headline)
                .foregroundStyle(Color(nsColor: .systemGreen).gradient)
            } else {
              Label("Disabled", systemImage: "stop.fill")
                .font(.headline)
                .foregroundStyle(Color(nsColor: .systemRed).gradient)
            }
          }
          GridRow(alignment: .lastTextBaseline) {
            Text("Tunneling:")
              .font(.callout)
            if self.tailscale.tunnelingEnabled {
              Label("Enabled", systemImage: "circle.fill")
                .font(.headline)
                .foregroundStyle(Color(nsColor: .systemGreen).gradient)
            } else {
              Label("Disabled", systemImage: "stop.fill")
                .font(.headline)
                .foregroundStyle(Color(nsColor: .systemRed).gradient)
            }
          }
        }
      }
    } else {
      Text("Tailscale not running or not connected")
        .font(.title)
    }
  }
}
