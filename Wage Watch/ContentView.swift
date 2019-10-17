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
    
    @State private var elapsed: Double = {
        return UserDefaults.standard.double(forKey: "Elapsed")
    }()
    
    @State private var earned: Double = 0
    
    @State private var startDate: Date? = {
        if let startDate = UserDefaults.standard.object(forKey: "StartDate") as? Date {
            return startDate
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
    
    private let accentColor: Color = Color(red: 133.0 / 255.0, green: 187.0 / 255.0, blue: 101.0 / 255.0)
    
    private func updateEarned() {
        self.earned = (self.elapsed + self.elapsedSinceStart) * self.secondlyWage
    }
    
    private func start() {
        let timeInterval = 0.01 / secondlyWage
        updateEarned()
        
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
            self.updateEarned()
        }
    }
    
    private func stop() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
            elapsed += elapsedSinceStart
            UserDefaults.standard.set(elapsed, forKey: "Elapsed")
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
                    }.accentColor(self.accentColor)
                }
                Spacer()
                if timer == nil {
                    if self.elapsed > 0 {
                        Button(action: {
                            self.earned = 0
                            self.elapsed = 0
                        }) {
                            Text("Reset")
                        }
                    }
                    Button(action: {
                        self.startDate = Date()
                        UserDefaults.standard.set(self.startDate, forKey: "StartDate")
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
