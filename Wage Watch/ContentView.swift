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
    
    @State private var earnedCurrent: Double = 0
    
    @State private var startDate: Date? = {
        print("In startDate initializer")
        return UserDefaults.standard.object(forKey: "StartDate") as? Date
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
    
    private var earnedSinceStart: TimeInterval {
        return secondlyWage * {
            if let startDate = startDate {
                return Date().timeIntervalSince(startDate)
            } else {
                return 0
            }
        }()
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
    
    private let accentColor: Color = Color(red: 133.0 / 255.0, green: 187.0 / 255.0, blue: 101.0 / 255.0)
    
    private func updateEarnedCurrent() {
        earnedCurrent = earned + earnedSinceStart
    }
    
    private func start() {
        if startDate == nil {
            startDate = Date()
        }
        
        UserDefaults.standard.set(startDate, forKey: "StartDate")
        self.updateEarnedCurrent()
        let timeInterval = 0.01 / secondlyWage

        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
            self.updateEarnedCurrent()
        }
    }
    
    private func stop() {
        timer?.invalidate()
        timer = nil
        earned += earnedSinceStart
        UserDefaults.standard.set(earned, forKey: "Earned")
        startDate = nil
        UserDefaults.standard.removeObject(forKey: "StartDate")
    }
    
    private func reset() {
        earnedCurrent = 0
        earned = 0
        UserDefaults.standard.set(0, forKey: "Earned")
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
                    }.accentColor(self.accentColor)
                }
                Spacer()
                if startDate == nil {
                    if earned > 0 {
                        Button(action: {
                            self.reset()
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
            Text(currencyNumberFormatter.string(from: NSNumber(value: earnedCurrent)) ?? "")
                .font(.largeTitle)
                .bold()
                .onAppear(perform: {
                    if self.startDate != nil {
                        self.start()
                    }
                })
        }.accentColor(accentColor)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
