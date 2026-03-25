import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var date: Date
    var transactionDescription: String
    var amount: Double
    var bankName: String
    var category: Category?

    init(date: Date, transactionDescription: String, amount: Double, bankName: String) {
        self.id = UUID()
        self.date = date
        self.transactionDescription = transactionDescription
        self.amount = amount
        self.bankName = bankName
    }

    var isExpense: Bool { amount < 0 }
    var isIncome: Bool { amount > 0 }
    var absoluteAmount: Double { abs(amount) }
}
