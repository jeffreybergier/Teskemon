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
  
  public var body: some View {
    NavigationStack {
      Table(self.controller?.nodes ?? []) {
        TableColumn("") { node in
          Image(systemName: node.isOnline ? "circle.fill" : "stop.fill")
            .foregroundStyle(node.isOnline
                             ? Color(nsColor: .systemGreen).gradient
                             : Color(nsColor: .systemRed).gradient)
        }
        .width(24)
        TableColumn("Machine") { node in
          HStack(alignment: .center) {
            Group {
              if (self.controller?.selfNodeID == node.id) {
                Image(systemName: "house")
              } else {
                Image(systemName: "network")
              }
            }
            .font(.title)
            VStack(alignment: .leading) {
              HStack(alignment:.firstTextBaseline) {
                Text(node.hostname).font(.headline)
                Text(node.os).font(.subheadline)
              }
              Text(node.url).font(.subheadline)
            }
          }
        }
        TableColumn("Activity") { node in
          HStack(alignment: .center) {
            Group {
              if (node.isActive) {
                Image(systemName: "progress.indicator")
              } else {
                Image(systemName: "pause.circle")
              }
            }
            .font(.title)
            VStack(alignment: .leading) {
              Label(byteF.string(fromByteCount: node.txBytes),
                    systemImage:"chevron.up")
              Label(byteF.string(fromByteCount: node.rxBytes),
                    systemImage:"chevron.down")
            }
            .font(.subheadline)
          }
        }
      }
      .navigationTitle("Home")
      .toolbar {
        ToolbarItem {
          Button("Update") {
            self._controller.updateAll()
          }
        }
      }
    }
  }
}
