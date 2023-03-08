//
//  TransactionListViewModel.swift
//  ExpenseTracker
//
//  Created by Bastien Orbigo on 3/6/23.
//

import Foundation
import Combine
import Collections //needed for OrderedDictionary

typealias TransactionGroup = OrderedDictionary<String, [Transaction]>
//String : Date, Double : Amount
typealias TransactionPrefixSum = [(String, Double)]

/*
 ObservableObject is part of the framework that turns any object into a publisher
 and notifies users of state changes so they know to update their views
 */
final class TransactionListViewModel: ObservableObject {
    //@Published is responsible for notifying subscribers of changes
    @Published var transactions: [Transaction] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    //called when it's initialized
    init() {
        getTransactions()
    }
    
    func getTransactions() {
        //guard checks if url is valid
        guard let url = URL(string: "https://designcode.io/data/transactions.json") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { (data, response) -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    //dump is like print but for cleanly displaying complex object info
                    dump(response)
                    
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: [Transaction].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print("Error fetching transactions: ", error.localizedDescription)
                case .finished:
                    print("Finished fetching transactions")
                }
            } receiveValue: { [weak self] result in
                self?.transactions = result
            }
            .store(in: &cancellables)
    }
    
    func groupTransactionsByMonth() -> TransactionGroup {
        //make sure transactions is not empty, otherwise return an empty dictionary
        guard !transactions.isEmpty else { return [:] }
        
        let groupedTransactions = TransactionGroup(grouping: transactions) { $0.month }
        
        return groupedTransactions
    }
    
    func accumulateTransactions() -> TransactionPrefixSum {
        print("accumulateTransactions")
        guard !transactions.isEmpty else { return [] }
        
        let today = "02/17/2022".dateParsed() //Date()
        let dateInterval = Calendar.current.dateInterval(of: .month, for: today)!
        print("dateInterval", dateInterval)
        
        var sum: Double = .zero
        var cumulativeSum = TransactionPrefixSum()
        
        for date in stride(from: dateInterval.start, to: today, by: 60 * 60 * 24) { //60 seconds * 60 minutes * 24 hours
            let dailyExpenses = transactions.filter { $0.dateParsed == date && $0.isExpense }
            let dailyTotal = dailyExpenses.reduce(0) { $0 - $1.signedAmount }
            
            sum += dailyTotal
            sum = sum.roundedTo2Digits()
            cumulativeSum.append((date.formatted(), sum))
            print(date.formatted(), "dailyTotal: ", dailyTotal, "sum: ", sum)
        }
        
        return cumulativeSum
    }
}
