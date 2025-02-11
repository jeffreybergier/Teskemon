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
  
  public  static let id:          String  = "ABOUT"
  private static let imageSize:   CGFloat = 142
  private static let windowWidth: CGFloat = 500
  
  public init() {}
  
  public var body: some View {
    VStack {
      HStack(alignment: .top) {
        self.aboutImage
          .frame(width: AboutWindow.imageSize,
                 height: AboutWindow.imageSize)
        Grid {
          GridRow {
            Text(.appName   ).gridCellAnchor(.topTrailing)
            Text(.appNameEng).gridCellAnchor(.topLeading)
          }
          .font(.title)
          GridRow {
            Text(.appTagLine   ).gridCellAnchor(.trailing)
            Text(.appTagLineEng).gridCellAnchor(.leading)
          }
          .font(.title3)
          GridRow {
            Divider()
              .gridCellColumns(2)
          }
          GridRow {
            Text(.aboutDescription)
              .font(.body)
              .fixedSize(horizontal: false, vertical: true)
              .gridCellColumns(2)
          }
          GridRow {
            Button("github.com/jeffreybergier/teskemon") {
              NSWorkspace.shared.open(URL(string: "https://github.com/jeffreybergier/Teskemon")!)
            }
            .font(.body)
            .buttonStyle(.link)
            .gridCellAnchor(.leading)
            .gridCellColumns(2)
          }
          GridRow {
            Button("jeffburg.social/tags/Tailscale") {
              NSWorkspace.shared.open(URL(string: "https://jeffburg.social/tags/Tailscale")!)
            }
            .font(.body)
            .buttonStyle(.link)
            .gridCellAnchor(.leading)
            .gridCellColumns(2)
          }
        }
      }
      Divider()
      Text(.aboutCopyright)
        .font(.caption)
    }
    .navigationTitle(.aboutTeskemon)
    .frame(width: AboutWindow.windowWidth)
    .padding()
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
        .clipShape(RoundedRectangle(cornerRadius: 8))
    } else {
      Image(systemName: .imageStatusError)
    }
  }
}
