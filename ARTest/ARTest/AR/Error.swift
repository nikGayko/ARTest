//
//  Error.swift
//  ARTest
//
//  Created by Mikita Haiko on 2/17/21.
//  Copyright © 2021 Mikita Haiko. All rights reserved.
//

import Foundation

enum ARError: Error {
    case unknown
    case notEnoughObjects
    case custom(description: String)
}

extension ARError {
    init(error: Error) {
        self = .custom(description: error.localizedDescription)
    }
}

extension ARError {
    var localizedDescription: String {
        switch self {
        case .unknown:
            return "error.unknown"
        case .notEnoughObjects:
            return "error.notEnoughObjects"
        case .custom(description: let description):
            return description
        }
    }
}
