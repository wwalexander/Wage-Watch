//
//  Currency.swift
//  Wage Watch
//
//  Created by William Alexander on 10/7/19.
//  Copyright © 2019 William Alexander. All rights reserved.
//

import Foundation

struct Currency: CustomStringConvertible, Equatable, Hashable {
    var locale: Locale
    var code: String
    
    var description: String {
        let localizedString: String = {
            if let localizedString = locale.localizedString(forCurrencyCode: code) {
                return " (\(localizedString))"
            } else {
                return ""
            }
        }()
        
        return "\(code)\(localizedString)"
    }
    
    init(locale: Locale) {
        self.locale = locale
        self.code = locale.currencyCode ?? ""
    }
}
