//
//  Created by Jeffrey Bergier on 2025/01/25.
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

import Foundation

public struct Presentation: Codable {
  
  public var settingsTab = SettingsTab.tailscale
  public var tableSelection = Set<Machine.Identifier>()
  public var infoPanel: InfoPanel = .init()
  public init() { }
}

extension Presentation {
  
  public enum SettingsTab: Codable {
    case tailscale
    case services
    case scanning
  }
  
  public enum InfoPanelTab: Int, Codable {
    case info, names, passwords
  }
  
  public struct InfoPanel: Codable {
    
    public var isPresented: Bool
    public var currentTab:  InfoPanelTab
    public var isExpanded:  [Machine.Identifier: Bool] = [:]
    public init(tab: Presentation.InfoPanelTab,
                selection: Set<Machine.Identifier>)
    {
      self.isPresented = true
      self.currentTab = tab
    }
    
    public init() {
      self.isPresented = false
      self.currentTab = .info
    }
  }
}


