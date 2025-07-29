import SwiftUI
import CoreData

// MARK: - AllCategoriesSummaryView та супутні компоненти
extension AppView {
    struct AllCategoriesSummaryView: View {
        // MARK: - Властивості
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
                    let lhsExpenses = PersistenceController.shared.totalExpenses(
                        for: transactions.filter { $0.validCategory == lhs },
                        targetCurrency: currencyManager.baseCurrency1,
                        currencyManager: currencyManager
                    )
                    let rhsExpenses = PersistenceController.shared.totalExpenses(
                        for: transactions.filter { $0.validCategory == rhs },
                        targetCurrency: currencyManager.baseCurrency1,
                        currencyManager: currencyManager
                    )
                    return lhsExpenses > rhsExpenses
                }
            }
        }

        // MARK: - Body
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

        // MARK: - Підкомпоненти Summary
        private var totalExpensesSummary: some View {
            let filteredTransactions = transactions.filter {
                $0.validCategory != "Поповнення" &&
                $0.validCategory != "На інший рахунок" &&
                $0.validCategory != "API"
            }
            let totalUAH = PersistenceController.shared.totalExpenses(
                for: filteredTransactions,
                targetCurrency: currencyManager.baseCurrency1,
                currencyManager: currencyManager
            )
            let totalPLN = PersistenceController.shared.totalExpenses(
                for: filteredTransactions,
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
            let totalUAH = PersistenceController.shared.totalReplenishment(
                for: filteredTransactions,
                targetCurrency: currencyManager.baseCurrency1,
                currencyManager: currencyManager
            )
            let totalPLN = PersistenceController.shared.totalReplenishment(
                for: filteredTransactions,
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
                    totalUAH = PersistenceController.shared.totalToOtherAccount(
                        for: filteredTransactions,
                        targetCurrency: currencyManager.baseCurrency1,
                        currencyManager: currencyManager
                    )
                    totalPLN = PersistenceController.shared.totalToOtherAccount(
                        for: filteredTransactions,
                        targetCurrency: currencyManager.baseCurrency2,
                        currencyManager: currencyManager
                    )
                } else {
                    totalUAH = PersistenceController.shared.totalExpenses(
                        for: filteredTransactions,
                        targetCurrency: currencyManager.baseCurrency1,
                        currencyManager: currencyManager
                    )
                    totalPLN = PersistenceController.shared.totalExpenses(
                        for: filteredTransactions,
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
}
