//
//  ContentView.swift
//  Wage Watch
//
//  Created by William Alexander on 10/7/19.
//  Copyright © 2019 William Alexander. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var wage: Double = {
        let wage = UserDefaults.standard.double(forKey: "Wage")
        return wage == 0 ? 7.25 : wage
    }()
    
    @State private var currencyIndex: Int = {
        return UserDefaults.standard.integer(forKey: "Currency")
    }()
    
    @State private var periodIndex: Int = {
        return UserDefaults.standard.integer(forKey: "Period")
    }()
    
    @State private var earned: Double = {
        return UserDefaults.standard.double(forKey: "Earned")
    }()
    
    @State private var earnedPrevious: Double = 0
    
    @State private var startDate: Date? = {
        if let startDate = UserDefaults.standard.object(forKey: "StartDate") {
            return startDate as? Date
        } else {
            return nil
        }
    }()
    
    @State private var wageConfigurationIsPresented: Bool = false
    @State private var timer: Timer?
    
    private let currencies: [Currency] = {
        var currencyCodes: Set<String> = []
       
        let currencies: [Currency] = Locale.availableIdentifiers.compactMap {
           let locale = Locale(identifier: $0)
           if locale.languageCode != Locale.current.languageCode { return nil }
           let currency = Currency(locale: locale)
           if currency.code == "" { return nil }
           if currencyCodes.contains(currency.code) { return nil }
           currencyCodes.insert(currency.code)
           return currency
        }.sorted {
           $0.code == Locale.current.currencyCode || $0.code < $1.code
        }
       
        return currencies
    }()
    
    private let periods: [Period] = [.hour, .day, .month, .year]
    
    private var secondlyWage: TimeInterval {
        return wage / periods[periodIndex].rawValue
    }
    
    private var elapsedSinceStart: TimeInterval {
        if let startDate = startDate {
            return Date().timeIntervalSince(startDate)
        } else {
            return 0
        }
    }

    private let decimalNumberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        return numberFormatter
    }()
    
    private var currencyNumberFormatter: NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = currencies[currencyIndex].locale
        return numberFormatter
    }
    
    private func start() {
        earnedPrevious = earned
        startDate = Date()
        UserDefaults.standard.set(startDate, forKey: "StartDate")
        let timeInterval = 0.01 / secondlyWage
        
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
            self.earned = self.earnedPrevious + self.elapsedSinceStart * self.secondlyWage
        }
    }
    
    private func stop() {
        if timer != nil {
            timer?.invalidate()
            earned = earnedPrevious + elapsedSinceStart * secondlyWage
            UserDefaults.standard.set(earned, forKey: "Earned")
            timer = nil
            startDate = nil
            UserDefaults.standard.removeObject(forKey: "StartDate")
        }
    }
    
    private func persistWageConfiguration() {
        UserDefaults.standard.set(self.wage, forKey: "Wage")
        UserDefaults.standard.set(self.currencyIndex, forKey: "Currency")
        UserDefaults.standard.set(self.periodIndex, forKey: "Period")
    }
    
    var body: some View {
        ZStack {
            VStack {
                Button(action: {
                    self.stop()
                    self.wageConfigurationIsPresented = true
                }) {
                    return Text("\(self.currencyNumberFormatter.string(from: NSNumber(value: self.wage)) ?? "") \(self.periods[self.periodIndex].description)")
                }
                .padding(.top)
                .sheet(isPresented: $wageConfigurationIsPresented, onDismiss: {
                    self.persistWageConfiguration()
                }) {
                    NavigationView {
                        Form {
                            HStack {
                                Text("Wage")
                                TextField("", value: self.$wage, formatter: self.decimalNumberFormatter)
                                    // TODO: Replace with .decimalPad once SwiftUI supports a Done button for it
                                    .keyboardType(.numbersAndPunctuation)
                                    .multilineTextAlignment(.trailing)
                            }
                            Picker(selection: self.$currencyIndex, label: Text("Currency")) {
                                ForEach(self.currencies.indices, id: \.self) {
                                    Text(self.currencies[$0].code).tag($0)
                                }
                            }
                            Picker(selection: self.$periodIndex, label: Text("Period")) {
                                ForEach(self.periods.indices, id: \.self) {
                                    Text(self.periods[$0].description).tag($0)
                                }
                            }
                        }
                            .navigationBarTitle("Wage", displayMode: .inline)
                            .navigationBarItems(trailing: Button(action: {
                                self.persistWageConfiguration()
                                self.wageConfigurationIsPresented = false
                            }) {
                                Text("Done")
                            })
                    }
                }
                Spacer()
                if startDate == nil {
                    if self.earned > 0 {
                        Button(action: {
                            self.earned = 0
                        }) {
                            Text("Reset")
                        }
                    }
                    Button(action: {
                        self.start()
                    }) {
                        Text("Start")
                    }
                        .font(.title)
                        .padding()
                } else {
                    Button(action: {
                        self.stop()
                    }) {
                        Text("Stop")
                    }
                        .font(.title)
                        .padding()
                }
            }
            Text(currencyNumberFormatter.string(from: NSNumber(value: earned)) ?? "")
                .font(.largeTitle)
                .bold()
                .onAppear(perform: {
                    if self.startDate != nil {
                        self.earned += self.elapsedSinceStart * self.secondlyWage
                        self.start()
                    }
                })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
