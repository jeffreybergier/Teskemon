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
extension LocalizedStringKey {
  static let appName:        LocalizedStringKey = "テスケモン"
  static let tailscale:      LocalizedStringKey = "Tailscale"
  static let netcat:         LocalizedStringKey = "Netcat"
  static let magicDNS:       LocalizedStringKey = "MagicDNS"
  static let tunneling:      LocalizedStringKey = "Tunneling"
  static let nodeKey:        LocalizedStringKey = "Node Key"
  static let noData:         LocalizedStringKey = "No Data"
  static let general:        LocalizedStringKey = "General"
  static let open:           LocalizedStringKey = "Open"
  static let done:           LocalizedStringKey = "Done"
  static let edit:           LocalizedStringKey = "Edit"
  static let save:           LocalizedStringKey = "Save"
  static let add:            LocalizedStringKey = "Add"
  static let delete:         LocalizedStringKey = "Delete"
  static let reset:          LocalizedStringKey = "Reset"
  static let error:          LocalizedStringKey = "Error"
  static let dismiss:        LocalizedStringKey = "Dismiss"
  static let machineInfo:    LocalizedStringKey = "Machine Information"
  static let machineRefresh: LocalizedStringKey = "Machine Refresh"
  static let serviceRefresh: LocalizedStringKey = "Service Refresh"
  static let information:    LocalizedStringKey = "Information"
  static let name:           LocalizedStringKey = "Name"
  static let names:          LocalizedStringKey = "Names"
  static let nameOriginal:   LocalizedStringKey = "Original Name"
  static let nameCustom:     LocalizedStringKey = "Custom Name"
  static let username:       LocalizedStringKey = "Username"
  static let password:       LocalizedStringKey = "Password"
  static let passwords:      LocalizedStringKey = "Passwords"
  static let online:         LocalizedStringKey = "Online"
  static let kind:           LocalizedStringKey = "Kind"
  static let relay:          LocalizedStringKey = "Relay"
  static let machine:        LocalizedStringKey = "Machine"
  static let machines:       LocalizedStringKey = "Machines"
  static let services:       LocalizedStringKey = "Services"
  static let activity:       LocalizedStringKey = "Activity"
  static let scheme:         LocalizedStringKey = "Scheme"
  static let port:           LocalizedStringKey = "Port"
  static let ping:           LocalizedStringKey = "Ping"
  static let clearCache:     LocalizedStringKey = "Clear Cache"
  static let refresh:        LocalizedStringKey = "Refresh"
  static let refreshAuto:    LocalizedStringKey = "Automatic Refresh"
  static let selectedAll:    LocalizedStringKey = "All Selected"
  static let account:        LocalizedStringKey = "Account"
  static let domain:         LocalizedStringKey = "Domain"
  static let enabled:        LocalizedStringKey = "Enabled"
  static let disabled:       LocalizedStringKey = "Disabled"
  static let present:        LocalizedStringKey = "Present"
  static let missing:        LocalizedStringKey = "Missing"
  static let version:        LocalizedStringKey = "Version"
  static let versionNew:     LocalizedStringKey = "Version – Up to Date"
  static let versionOld:     LocalizedStringKey = "Version – Update Available"
  static let timeout:        LocalizedStringKey = "Timeout"
  static let batchSize:      LocalizedStringKey = "Batch Size"
  static let automatic:      LocalizedStringKey = "Automatic"
  static let interval:       LocalizedStringKey = "Interval"
  static let location:       LocalizedStringKey = "Location"
  static let path:           LocalizedStringKey = "Path"
  static let commandLine:    LocalizedStringKey = "Command Line"
  static let appStore:       LocalizedStringKey = "App Store"
  static let custom:         LocalizedStringKey = "Custom"
  static let noValue:        LocalizedStringKey = "—"
  static func selected(_ count: Int) -> LocalizedStringKey {
    guard count > 0 else { return self.selectedAll }
    return "\(count) Selected"
  }
  
  // MARK: Verbs
  static let verbDeselectAll:       LocalizedStringKey = "Deselect All"
  static let verbSelectThisMachine: LocalizedStringKey = "Select this Machine"
  
  // MARK: Help
  static let helpNodeMe:           LocalizedStringKey = "This Node"
  static let helpNodeRemote:       LocalizedStringKey = "Peer Node"
  static let helpNodeSubnetMe:     LocalizedStringKey = "Route Advertised by This Node"
  static let helpNodeSubnetRemote: LocalizedStringKey = "Route Advertised by Peer Node"
  static let helpPingUnknown:      LocalizedStringKey = "Ping: Not yet run"
  static let helpPingError:        LocalizedStringKey = "Ping: Timeout"
  static let helpPingOnline:       LocalizedStringKey = "Ping: Machine Online"
  static let helpPingOffline:      LocalizedStringKey = "Ping: Machine Offline"
  static let helpPingProcessing:   LocalizedStringKey = "Pinging"
  static let helpNetcatUnknown:    LocalizedStringKey = "Netcat: Not yet scanned"
  static let helpNetcatError:      LocalizedStringKey = "Netcat: Timeout"
  static let helpNetcatOnline:     LocalizedStringKey = "Netcat: Port listening"
  static let helpNetcatOffline:    LocalizedStringKey = "Netcat: Port not listening"
  static let helpNetcatProcessing: LocalizedStringKey = "Netcat: Scanning"
  
  // MARK: Error
  static let errorPasswordEmpty:   LocalizedStringKey = "Username or password is missing"
  static let errorPasswordData:    LocalizedStringKey = "This password does not belong to this machine and should be deleted"
  static let errorPasswordDamaged: LocalizedStringKey = "This password is damaged and should be deleted"

}

extension String {
  static let noValue               = "—"
  static let error                 = "Error"
  static let imageInfo             = "info"
  static let imagePerson           = "person"
  static let imageNetwork          = "network"
  static let imageMachine          = "desktopcomputer"
  static let imagePasswords        = "ellipsis.rectangle"
  static let imageTrash            = "trash"
  static let imageSettings         = "gear"
  static let imageServices         = "slider.horizontal.3"
  static let imageAdd              = "plus"
  static let imageEdit             = "pencil"
  static let imageSave             = "checkmark"
  static let imageDeleteX          = "xmark"
  static let imageDeleteXCircle    = "x.circle"
  static let imageError            = "exclamationmark.triangle"
  static let imageReset            = "arrow.uturn.left"
  static let imageSelect           = "cursorarrow.rays"
  static let imageDeselect         = "cursorarrow.slash"
  static let imageRefresh          = "arrow.clockwise"
  static let imageRefreshAutoOn    = "autostartstop"
  static let imageRefreshAutoOff   = "autostartstop.slash"
  static let imageRefreshMachines  = "person.2.arrow.trianglehead.counterclockwise"
  static let imageRefreshServices  = "slider.horizontal.2.arrow.trianglehead.counterclockwise"
  static let imageStatusOnline     = "circle.fill"
  static let imageStatusOffline    = "stop.fill"
  static let imageStatusUnknown    = "questionmark.diamond.fill"
  static let imageStatusNoData     = "questionmark.square.dashed"
  static let imageStatusError      = "exclamationmark.triangle.fill"
  static let imageStatusProcessing = "progress.indicator"
  static let imageActivityActive   = "progress.indicator"
  static let imageActivityInactive = "pause.circle"
  static let imageActivityUnknown  = "circle.dotted"
  static let imageActivityUpDown   = "chevron.up.chevron.down"
  static let imageNodeMe           = "person.crop.rectangle"
  static let imageNodeRemote       = "rectangle"
  static let imageNodeMeSubnet     = "person.crop.rectangle.stack"
  static let imageNodeRemoteSubnet = "rectangle.stack"
}

extension Color {
  static let statusOnline     = Color(nsColor: .systemGreen ).gradient
  static let statusOffline    = Color(nsColor: .systemRed   ).gradient
  static let statusError      = Color(nsColor: .systemYellow).gradient
  static let statusUnknown    = Color(nsColor: .systemGray  ).gradient
  static let statusProcessing = Color(nsColor: .textColor   ).gradient
  
  static let HACK_showColorInMenus = Color.black
}

