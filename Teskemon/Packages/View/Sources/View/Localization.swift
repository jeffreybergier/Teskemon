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
  static let appNameEng:     LocalizedStringKey = "Teskemon"
  static let appTagLine:     LocalizedStringKey = "テールスケール専門"
  static let appTagLineEng:  LocalizedStringKey = "Tailscale Specialist"
  static let separatorDot:   LocalizedStringKey = "・"
  static let tailscale:      LocalizedStringKey = "Tailscale"
  static let netcat:         LocalizedStringKey = "Netcat (Port Scanning)"
  static let magicDNS:       LocalizedStringKey = "MagicDNS"
  static let tunneling:      LocalizedStringKey = "Tunneling"
  static let nodeKey:        LocalizedStringKey = "Node Key"
  static let noData:         LocalizedStringKey = "No Data"
  static let open:           LocalizedStringKey = "Open"
  static let done:           LocalizedStringKey = "Done"
  static let edit:           LocalizedStringKey = "Edit"
  static let save:           LocalizedStringKey = "Save"
  static let add:            LocalizedStringKey = "Add"
  static let delete:         LocalizedStringKey = "Delete"
  static let moveUp:         LocalizedStringKey = "Move Up"
  static let moveDown:       LocalizedStringKey = "Move Down"
  static let actions:        LocalizedStringKey = "Actions"
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
  static let displayName:    LocalizedStringKey = "Display Name"
  static let password:       LocalizedStringKey = "Password"
  static let passwords:      LocalizedStringKey = "Passwords"
  static let online:         LocalizedStringKey = "Online"
  static let kind:           LocalizedStringKey = "Kind"
  static let relay:          LocalizedStringKey = "Relay"
  static let machine:        LocalizedStringKey = "Machine"
  static let machines:       LocalizedStringKey = "Machines"
  static let services:       LocalizedStringKey = "Services"
  static let scanning:       LocalizedStringKey = "Scanning"
  static let activity:       LocalizedStringKey = "Activity"
  static let scheme:         LocalizedStringKey = "Scheme"
  static let port:           LocalizedStringKey = "Port"
  static let ping:           LocalizedStringKey = "Ping"
  static let count:          LocalizedStringKey = "Count"
  static let id:             LocalizedStringKey = "ID"
  static let host:           LocalizedStringKey = "Hostname"
  static let ip:             LocalizedStringKey = "IP Address"
  static let opSystem:       LocalizedStringKey = "Operating System"
  static let created:        LocalizedStringKey = "Created"
  static let lastWrite:      LocalizedStringKey = "Last Write"
  static let lastHandshake:  LocalizedStringKey = "Last Handshake"
  static let inNetworkMap:   LocalizedStringKey = "In Network Map"
  static let inMagicSock:    LocalizedStringKey = "In Magic Sock"
  static let inEngine:       LocalizedStringKey = "In Engine"
  static let userID:         LocalizedStringKey = "User ID"
  static let roles:          LocalizedStringKey = "Roles"
  static let profPic:        LocalizedStringKey = "Profile Picture"
  static let yes:            LocalizedStringKey = "Yes"
  static let no:             LocalizedStringKey = "No"
  static let lossThreshold:  LocalizedStringKey = "Loss Threshold"
  static let subnetRoutes:   LocalizedStringKey = "Subnet Routes"
  static let relationship:   LocalizedStringKey = "Relationship"
  static let publicKey:      LocalizedStringKey = "Public Key"
  static let keyExpiry:      LocalizedStringKey = "Key Expiry"

  static let clearCache:     LocalizedStringKey = "Clear Cache"
  static let refresh:        LocalizedStringKey = "Refresh"
  static let refreshAuto:    LocalizedStringKey = "Automatic Refresh"
  static let selectedAll:    LocalizedStringKey = "All Selected"
  static let account:        LocalizedStringKey = "Account"
  static let tailnet:        LocalizedStringKey = "Tailnet"
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
  static let customPath:     LocalizedStringKey = "Custom Path"
  static let commandLine:    LocalizedStringKey = "Command Line"
  static let appStore:       LocalizedStringKey = "App Store"
  static let custom:         LocalizedStringKey = "Custom"
  static let noValue:        LocalizedStringKey = "—"
  static func selected(_ count: Int) -> LocalizedStringKey {
    guard count > 0 else { return self.selectedAll }
    return "\(count) Selected"
  }
  static func relayTailscale(_ name: String) -> LocalizedStringKey {
    return "Tailscale Relay: '\(name)'"
  }
  static func relayRoute(_ name: String) -> LocalizedStringKey {
    return "Subnet Route of: '\(name)'"
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

  // MARK: Settings Explanation
  static let settingsNetcatTimeout: LocalizedStringKey = "Increasing the timeout will increase the accuracy of the port scanning, but it could slow down the process."
  static let settingsPingCount:     LocalizedStringKey = "Increasing the count will increase the accuracy of the ping, but it will slow down the process."
  static let settingsPingLoss:      LocalizedStringKey = "The higher the loss threshold, the more likely it is that the ping will detect a machine is online."

  static let aboutDescription:      LocalizedStringKey = """
                                                         Teskemon is a SwiftUI application built to monitor Tailscale networks. \
                                                         It is provided under the GPLv3 Open Source license and without any warranty or liability. \
                                                         If this application is useful for you, please use as you wish and provide feedback. \
                                                         And yes, I do accept pull requests.
                                                         """
}

extension String {
  // MARK: Text
  static let noValue               = "—"
  
  // MARK: Errors
  static let errorUnknown          = "Unknown Error"
  static let errorKeychain         = "Keychain Error"
  static let errorPasswordEmpty    = "Username or password is missing"
  static let errorPasswordData     = "This password does not belong to this machine and should be deleted"
  static let errorPasswordDamaged  = "This password is damaged and should be deleted"
  static func errorMessage(_ error: CustomNSError) -> String {
    "→Error Code: \(error.errorCode)←\n" + error.localizedDescription
  }
  
  // MARK: Images
  static let imageInfo             = "info"
  static let imagePerson           = "person"
  static let imageSafari           = "safari"
  static let imageNetwork          = "network"
  static let imageMachine          = "desktopcomputer"
  static let imagePasswords        = "ellipsis.rectangle"
  static let imageTrash            = "trash"
  static let imageSettings         = "gear"
  static let imageServices         = "slider.horizontal.3"
  static let imageScanning         = "wifi"
  static let imageAdd              = "plus"
  static let imageEdit             = "pencil"
  static let imageSave             = "checkmark"
  static let imageDeleteX          = "xmark"
  static let imageDeleteXCircle    = "x.circle"
  static let imageArrowUp          = "chevron.up"
  static let imageArrowDown        = "chevron.down"
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

// MARK: CustomNSError

import Model
import Controller

extension Password.Error: @retroactive CustomNSError {
  public static var errorDomain: String { .errorKeychain }
  public var errorUserInfo: [String : Any] {
    let message: String
    switch self {
    case .missingUsernameOrPassword: message = .errorPasswordEmpty
    case .machineDataIncorrect:      message = .errorPasswordData
    case .criticalDataIncorrect:     message = .errorPasswordDamaged
    case .keychain(let status):      message = status.secErrorMessage
    }
    return [
      NSLocalizedDescriptionKey: message
    ]
  }
}

extension Process.Output: @retroactive CustomNSError {
  public static var errorDomain: String { "Command Line Error" }
  public var errorCode: Int { self.exitCode }
  public var errorUserInfo: [String : Any] {
    let description = String(data: self.errOut, encoding: .utf8)
                   ?? String(data: self.stdOut, encoding: .utf8)
                   ?? .errorUnknown
    return [
      NSLocalizedDescriptionKey: description.trimmed!
    ]
  }
}

extension View {
  internal func alert(error binding: Binding<CustomNSError?>,
                      onDismiss: ((CustomNSError) -> Void)? = nil)
                      -> some View
  {
    let title = binding.wrappedValue.map { type(of:$0).errorDomain } ?? .errorUnknown
    return self.alert(item: binding, title: title) { error in
      Button(.dismiss) {
        onDismiss?(error)
      }
    } message: { error in
      Text(String.errorMessage(error))
    }
  }
}
