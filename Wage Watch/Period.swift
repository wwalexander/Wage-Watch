//
//  Period.swift
//  Wage Watch
//
//  Created by William Alexander on 10/7/19.
//  Copyright © 2019 William Alexander. All rights reserved.
//

import Foundation

enum Period: TimeInterval, CaseIterable, CustomStringConvertible, Identifiable {
    
    case hour = 3_600, day = 86_400, month = 2_629_800, year = 31_557_600
    
    var id: TimeInterval {
        return self.rawValue
    }
    
    init?(_ timeInterval: TimeInterval) {
        switch timeInterval {
        case      3_600: self = .hour
        case     86_400: self = .day
        case  2_629_800: self = .month
        case 31_557_600: self = .year
        default: return nil
        }
    }
    
    var description: String {
        switch self {
        case .hour: return  "per hour"
        case .day: return   "per day"
        case .month: return "per month"
        case .year: return  "per year"
        }
    }
    
}
