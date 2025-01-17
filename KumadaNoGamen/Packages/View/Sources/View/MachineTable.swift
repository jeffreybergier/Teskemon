//
//  Created by Jeffrey Bergier on 2025/01/12.
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

internal struct MachineTable: View {
  
  @Binding internal var model: MachineModel
  @State internal var services: [Service]
  
  internal var body: some View {
    Table(self.model.allIDs, selection: self.$model.selectedIDs) {
      
      TableColumn("Online") { id in
        TableRowOnline(isOnline: self.model.machine(for: id).activity?.isOnline)
      }.width(24)
      
      TableColumn("Kind") { id in
        TableRowKind(kind: self.model.machine(for: id).kind)
      }.width(24)
      
      TableColumn("Relay") { id in
        TableRowRelay(relay: self.model.machine(for: id).relay)
      }.width(ideal: 48)
      
      TableColumn("Machine") { id in
        TableRowName(machine: self.model.machine(for: id))
      }.width(ideal: 128)
      
      TableColumn("Activity") { id in
        TableRowActiity(activity: self.model.machine(for: id).activity)
      }.width(ideal: 96)
      
      TableColumnForEach(self.services, id: \.self) { service in
        TableColumn(service.name + String(format: " (%d)", service.port)) { id in
          TableRowStatus(status: self.model.status(for: service, on: id),
                         url: self.model.url(for: service, on: id))
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
      Image(systemName: "circle.dotted")
        .foregroundStyle(Color(nsColor: .systemGray))
    case .some(true):
      Image(systemName: "circle.fill")
        .foregroundStyle(Color(nsColor: .systemGreen).gradient)
    case .some(false):
      Image(systemName: "stop.fill")
        .foregroundStyle(Color(nsColor: .systemGreen).gradient)
    }
  }
}

internal struct TableRowKind: View {
  
  internal let kind: MachineKind
  
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
  
  internal let relay: MachineRelay
  
  internal var body: some View {
    Text(self.relay.displayName)
      .font(.subheadline)
      .help(self.relay.displayName)
  }
}

internal struct TableRowName: View {
  internal let machine: Machine
  internal var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment:.firstTextBaseline) {
        Text(self.machine.name).font(.headline)
        if let os = self.machine.os {
          Text(os).font(.subheadline)
        }
      }
      Text(self.machine.url).font(.subheadline)
    }
  }
}

internal struct TableRowActiity: View {
  
  private let byteF = ByteCountFormatter()
  
  internal let activity: MachineActivity?
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
