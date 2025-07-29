// Month Budget/Views/Screens/AllCategoriesSummaryView.swift
import SwiftUI
import CoreData

struct AllCategoriesSummaryView: View {
    let transactions: FetchedResults<Transaction>
    @EnvironmentObject var categoryDataModel: CategoryDataModel
    @EnvironmentObject var currencyDataModel: CurrencyDataModel
    @Binding var categoryFilterType: CategoryFilterType

    private var currencyManager: CurrencyManager {
        CurrencyManager(currencyDataModel: currencyDataModel)
    }

    private var sortedCategories: [String] {
        let categories = categoryDataModel.filterOptions.filter {
            $0 != "Поповнення" && $0 != "API" && $0 != "Всі"
        }
        switch categoryFilterType {
        case .count:
            return categories.sorted { lhs, rhs in
                let lhsCount = transactions.filter { $0.validCategory == lhs }.count
                let rhsCount = transactions.filter { $0.validCategory == rhs }.count
                return lhsCount > rhsCount
            }
        case .alphabetical:
            return categories.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        case .expenses:
            return categories.sorted { lhs, rhs in
                let lhsExpenses = TransactionService.totalExpenses(
                    for: transactions.filter { $0.validCategory == lhs },
                    targetCurrency: currencyManager.baseCurrency1,
                    currencyManager: currencyManager
                )
                let rhsExpenses = TransactionService.totalExpenses(
                    for: transactions.filter { $0.validCategory == rhs },
                    targetCurrency: currencyManager.baseCurrency1,
                    currencyManager: currencyManager
                )
                return lhsExpenses > rhsExpenses
            }
        }
    }

    var body: some View {
        List {
            totalExpensesSummary
            replenishmentSummary
            ForEach(sortedCategories, id: \.self) { category in
                CategoryExpenseSummary(
                    category: category,
                    transactions: transactions,
                    color: categoryDataModel.colors[category] ?? .gray,
                    currencyManager: currencyManager
                )
            }
        }
        .listStyle(PlainListStyle())
    }

    private var totalExpensesSummary: some View {
        let filteredTransactions = transactions.filter {
            $0.validCategory != "Поповнення" &&
            $0.validCategory != "На інший рахунок" &&
            $0.validCategory != "API"
        }
        let totalUAH = TransactionService.totalExpenses(
            for: Array(filteredTransactions),
            targetCurrency: currencyManager.baseCurrency1,
            currencyManager: currencyManager
        )
        let totalPLN = TransactionService.totalExpenses(
            for: Array(filteredTransactions),
            targetCurrency: currencyManager.baseCurrency2,
            currencyManager: currencyManager
        )
        let rate = totalPLN != 0 ? totalUAH / totalPLN : 0.0

        return SummaryView(
            title: "Усі витрати",
            amountUAH: totalUAH,
            amountPLN: totalPLN,
            rate: rate,
            color: categoryDataModel.colors["Всі"] ?? .gray
        )
    }

    private var replenishmentSummary: some View {
        let filteredTransactions = transactions.filter { $0.validCategory == "Поповнення" }
        let totalUAH = TransactionService.totalReplenishment(
            for: Array(filteredTransactions),
            targetCurrency: currencyManager.baseCurrency1,
            currencyManager: currencyManager
        )
        let totalPLN = TransactionService.totalReplenishment(
            for: Array(filteredTransactions),
            targetCurrency: currencyManager.baseCurrency2,
            currencyManager: currencyManager
        )
        let rate = totalPLN != 0 ? totalUAH / totalPLN : 0.0

        return SummaryView(
            title: "Поповнення",
            amountUAH: totalUAH,
            amountPLN: totalPLN,
            rate: rate,
            color: categoryDataModel.colors["Поповнення"] ?? .gray
        )
    }
}


private extension AllCategoriesSummaryView {
    struct CategoryExpenseSummary: View {
        let category: String
        let transactions: FetchedResults<Transaction>
        let color: Color
        let currencyManager: CurrencyManager

        var body: some View {
            let filteredTransactions = transactions.filter { $0.validCategory == category }
            let totalUAH: Double
            let totalPLN: Double

            if category == "На інший рахунок" {
                totalUAH = TransactionService.totalToOtherAccount(
                    for: Array(filteredTransactions),
                    targetCurrency: currencyManager.baseCurrency1,
                    currencyManager: currencyManager
                )
                totalPLN = TransactionService.totalToOtherAccount(
                    for: Array(filteredTransactions),
                    targetCurrency: currencyManager.baseCurrency2,
                    currencyManager: currencyManager
                )
            } else {
                totalUAH = TransactionService.totalExpenses(
                    for: Array(filteredTransactions),
                    targetCurrency: currencyManager.baseCurrency1,
                    currencyManager: currencyManager
                )
                totalPLN = TransactionService.totalExpenses(
                    for: Array(filteredTransactions),
                    targetCurrency: currencyManager.baseCurrency2,
                    currencyManager: currencyManager
                )
            }
            let rate = totalPLN != 0 ? totalUAH / totalPLN : 0.0

            return SummaryView(
                title: category,
                amountUAH: totalUAH,
                amountPLN: totalPLN,
                rate: rate,
                color: color
            )
        }
    }

    struct SummaryView: View {
        let title: String
        let amountUAH: Double
        let amountPLN: Double
        let rate: Double
        let color: Color

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(title):")
                        .font(.headline)
                        .foregroundColor(color)
                    Spacer()
                }
                HStack {
                    Text("UAH: \(amountUAH, format: .number.precision(.fractionLength(2)))")
                    Spacer()
                    Text("PLN: \(amountPLN, format: .number.precision(.fractionLength(2)))")
                    Spacer()
                    Text("Курс: \(rate, format: .number.precision(.fractionLength(2)))")
                }
            }
            .padding()
            .background(color.opacity(0.2))
            .cornerRadius(8)
            .padding(.vertical, 4)
        }
    }
}
