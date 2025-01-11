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

@MainActor internal let byteF = ByteCountFormatter()

public struct ContentView: View {
  
  @Controller private var controller
  @Services private var services
  
  private func node(_ id: Tailscale.Node.Identifier) -> Tailscale.Node {
    return self.controller.nodes[id]!
  }
  
  public var body: some View {
    NavigationStack {
      Table(self.controller.nodeIDs) {
        TableColumn("Online") { id in
          Image(systemName: self.node(id).isActive ? "circle.fill" : "stop.fill")
            .foregroundStyle(self.node(id).isOnline
                             ? Color(nsColor: .systemGreen).gradient
                             : Color(nsColor: .systemRed).gradient)
        }
        .width(24)
        TableColumn("Region") { id in
          VStack(alignment: .center) {
            Group {
              if (self.controller.status?.selfNodeID == id) {
                Image(systemName: "house")
              } else {
                Image(systemName: "network")
              }
            }
            .font(.headline)
            Text(self.node(id).region)
              .font(.subheadline)
          }
        }
        .width(24)
        TableColumn("Machine") { id in
          VStack(alignment: .leading) {
            HStack(alignment:.firstTextBaseline) {
              Text(self.node(id).hostname).font(.headline)
              Text(self.node(id).os).font(.subheadline)
            }
            Text(self.node(id).url).font(.subheadline)
          }
        }
        TableColumn("Activity") { id in
          HStack(alignment: .center) {
            Group {
              if (self.node(id).isActive) {
                Image(systemName: "progress.indicator")
              } else {
                Image(systemName: "pause.circle")
              }
            }
            .font(.headline)
            VStack(alignment: .leading) {
              Label(byteF.string(fromByteCount: self.node(id).txBytes),
                    systemImage:"chevron.up")
              Label(byteF.string(fromByteCount: self.node(id).rxBytes),
                    systemImage:"chevron.down")
            }
            .font(.subheadline)
          }
        }
      }
      .navigationTitle("Home")
      .toolbar {
        ToolbarItem {
          Button("Machines") {
            Task {
              do {
                try await self._controller.updateMachines()
              } catch {
                NSLog("// TODO: Show an error dialog")
              }
            }
          }
        }
        ToolbarItem {
          Button("Services") {
            Task {
              do {
                try await self._controller.updateServices()
              } catch {
                NSLog("// TODO: Show an error dialog")
              }
            }
          }
        }
      }
    }
  }
}
