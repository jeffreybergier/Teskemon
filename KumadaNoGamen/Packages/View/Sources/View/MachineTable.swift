//
//  Created by Jeffrey Bergier on 15/1/18.
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

@MainActor internal let byteF = ByteCountFormatter()

internal struct MachineTable: View {
  
  @TableController private var controller
  @Services private var services
  
  internal var body: some View {
    Table(self.controller.ids) {
      TableColumn("Online") { id in
        TableRowOnline(isOnline: self.controller.machine(for: id).activity?.isOnline)
      }
      .width(24)
      TableColumn("Relay") { id in
        TableRowRelay(machine: self.controller.machine(for: id))
      }
      .width(64)
      TableColumn("Machine") { id in
        TableRowName(machine: self.controller.machine(for: id))
      }
      TableColumn("Activity") { id in
        HStack(alignment: .center) {
          Group {
            // TODO
            if (self.controller.machine(for: id).activity?.isActive ?? false) {
              Image(systemName: "progress.indicator")
            } else {
              Image(systemName: "pause.circle")
            }
          }
          .font(.headline)
          VStack(alignment: .leading) {
            // TODO
            Label(byteF.string(fromByteCount: self.controller.machine(for: id).activity?.txBytes ?? -1),
                  systemImage:"chevron.up")
            Label(byteF.string(fromByteCount: self.controller.machine(for: id).activity?.rxBytes ?? -1),
                  systemImage:"chevron.down")
          }
          .font(.subheadline)
        }
      }
      .width(96)
      TableColumnForEach(self.services, id: \.self) { service in
        TableColumn(service.name + String(format: " (%d)", service.port)) { id in
          Button {
            NSWorkspace.shared.open(self.controller.url(for: service, on: id))
          } label: {
            Label {
              Text("Connect")
            } icon: {
              switch self.controller.status(for: service, on: id) {
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
          .help("Open: " + self.controller.url(for: service, on: id).absoluteString)
        }
        .width(64)
      }
    }
  }
}

internal struct TableRowOnline: View {
  internal let isOnline: Bool?
  internal var body: some View {
    switch self.isOnline {
    case .none:
      Image(systemName: "questionmark.diamond.fill")
        .foregroundStyle(Color(nsColor: .systemGray).gradient)
    case .some(true):
      Image(systemName: "circle.fill")
        .foregroundStyle(Color(nsColor: .systemGreen).gradient)
    case .some(false):
      Image(systemName: "stop.fill")
        .foregroundStyle(Color(nsColor: .systemGreen).gradient)
    }
  }
}

internal struct TableRowRelay: View {
  
  internal let machine: Machine
  
  @TableController private var controller
  
  internal var body: some View {
    VStack(alignment: .leading) {
      Image(systemName: self.systemImage)
        .font(.headline)
      Text(self.labelText)
        .font(.subheadline)
    }
  }
  
  private var systemImage: String {
    switch self.machine.kind {
    case .meHost:
      return "house"
    case .remoteHost:
      return "network"
    case .meSubnet:
      fallthrough
    case .remoteSubnet:
      return "shuffle"
      
    }
  }
  
  private var labelText: String {
    switch self.machine.relay {
    case .left(let left):
      return left
    case .right(let right):
      return self.controller.machine(for: right).name
    }
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
