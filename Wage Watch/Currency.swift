//
//  Currency.swift
//  Wage Watch
//
//  Created by William Alexander on 10/7/19.
//  Copyright © 2019 William Alexander. All rights reserved.
//

import Foundation

struct Currency: Equatable, Hashable {
    var locale: Locale
    var code: String

    init(locale: Locale) {
        self.locale = locale
        self.code = locale.currencyCode ?? ""
    }
}
