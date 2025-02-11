//
//  Created by Jeffrey Bergier on 2025/02/11.
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

public struct AboutWindow: View {
  public init() {}
  public var body: some View {
    VStack {
      HStack(alignment: .top) {
        self.aboutImage
          .layoutPriority(-1)
        Grid {
          GridRow {
            Text(.appName)
              .gridCellAnchor(.trailing)
            Text(.appNameEng)
              .gridCellAnchor(.leading)
          }
          .font(.title)
          GridRow {
            Text(.appTagLine)
              .gridCellAnchor(.trailing)
            Text(.appTagLineEng)
              .gridCellAnchor(.leading)
          }
          .font(.title3)
          GridRow {
            Divider()
              .gridCellColumns(2)
          }
          GridRow {
            Text(.aboutDescription)
              .lineLimit(7, reservesSpace: true) // TODO: Figure out how to get a text view to flow text properly
              .frame(idealWidth: 200)
              .gridCellColumns(2)
          }
          GridRow {
            Button("github.com/jeffreybergier/teskemon") {
              NSWorkspace.shared.open(URL(string: "https://github.com/jeffreybergier/Teskemon")!)
            }
            .buttonStyle(.link)
            .gridCellColumns(2)
          }
          GridRow {
            Button("jeffburg.social/tags/Tailscale") {
              NSWorkspace.shared.open(URL(string: "https://jeffburg.social/tags/Tailscale")!)
            }
            .buttonStyle(.link)
            .gridCellColumns(2)
          }
        }
      }
      Divider()
      Text("Version \(self.versionString) (\(self.buildString))・Copyright © 2025 Jeffrey Bergier")
        .font(.caption)
    }
    .padding([.leading, .trailing, .bottom], 8)
    .fixedSize()
  }
  
  @ViewBuilder private var aboutImage: some View {
    if
      let url = Bundle.main.url(forResource: "About", withExtension: "tiff"),
      let data = try? Data(contentsOf: url),
      let image = Image(data: data)
    {
      image
        .resizable()
        .scaledToFit()
        .frame(width: 160)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    } else {
      Image(systemName: .imageStatusError)
        .frame(width: 160, height: 160)
    }
  }
  
  private var versionString: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
  }
  
  private var buildString: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
  }
}
