//
//  Created by Jeffrey Bergier on 2025/01/14.
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

import Foundation

public enum Either<
    Left: Codable & Sendable & Hashable,
    Right: Codable & Sendable & Hashable
  >: Codable, Sendable, Hashable
{
  case left(Left)
  case right(Right)
  public var left: Left? {
    switch self {
    case .left(let left): return left
    case .right: return nil
    }
  }
  public var right: Right? {
    switch self {
    case .right(let right): return right
    case .left: return nil
    }
  }
}
