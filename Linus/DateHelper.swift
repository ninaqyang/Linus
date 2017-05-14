//
//  DateHelper.swift
//  Linus
//
//  Created by Nina Yang on 5/14/17.
//  Copyright © 2017 Nina Yang. All rights reserved.
//

import Foundation

extension Date {
    func getCurrentDate() -> String {
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "yyyy-MM-dd"
        
        let currentDate = Date()
        let dateString = dayTimePeriodFormatter.string(from: currentDate)
        return dateString
    }
}
