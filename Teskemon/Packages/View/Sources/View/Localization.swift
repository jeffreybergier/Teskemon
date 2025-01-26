//
//  Created by Jeffrey Bergier on 2025/01/26.
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

@MainActor
extension Label<Text, Image> {
  internal static let info = Label("Info", systemImage: "info.circle")
  internal static let names = Label("Names", systemImage: "person")
  internal static let passwords = Label("Passwords", systemImage: "ellipsis.rectangle")
  internal static let edit = Label("Edit", systemImage: "desktopcomputer")
  internal static let machinesRefreshOn  = Label("Machines", systemImage: "autostartstop")
  internal static let machinesRefreshOff = Label("Machines", systemImage: "autostartstop.slash")
  internal static let servicesRefreshOn  = Label("Services", systemImage: "autostartstop")
  internal static let servicesRefreshOff = Label("Services", systemImage: "autostartstop.slash")
  internal static let noData = Label("No Data", systemImage: "questionmark.square.dashed")
  internal static let settingsGeneral = Label("General", systemImage: "gear")
  internal static let settingsServices = Label("General", systemImage: "gear")
  
  internal static let statusEnabled: some View = Label("Enabled", systemImage: "circle.fill")
                                                      .foregroundStyle(Color(nsColor: .systemGreen).gradient, .black)
  internal static func statusEnabled(_ text: String?) -> some View {
    Label(text ?? "–", systemImage: "circle.fill")
      .foregroundStyle(Color(nsColor: .systemGreen).gradient, .black.gradient)
  }
  internal static let statusDisabled: some View = Label("Disabled", systemImage: "stop.fill")
                                                       .foregroundStyle(Color(nsColor: .systemRed).gradient, .black)
  internal static func statusDisabled(_ text: String?) -> some View {
    Label(text ?? "–", systemImage: "stop.fill")
      .foregroundStyle(Color(nsColor: .systemRed).gradient, .black.gradient)
  }
  internal static let statusUnknown = Label("–", systemImage: "triangle.fill")
  internal static func statusUnknown(_ text: String?) -> some View {
    Label(text ?? "–", systemImage: "triangle.fill")
      .foregroundStyle(Color(nsColor: .systemYellow).gradient, .black.gradient)
  }
  internal static func personCircle(_ text: String?) -> Self {
    Label(text ?? "–", systemImage: "person.circle")
  }
  internal static func network(_ text: String?) -> Self {
    Label(text ?? "–", systemImage: "network")
  }
}


