ContentView.swift:
final class CategoryDataModel: ObservableObject
struct MainAppView: View
extension Text
extension Transaction
extension Text

SideBar.swift:
struct SidebarView
- struct CategoriesView
    - struct ScaleButtonStyle: ButtonStyle
    - struct RenameCategoryView: View
    - struct CategoryManagementView: View

Transactions    MainView.swift:
struct TransactionsMainView: View
* struct BudgetSummaryListView: View
    * struct BudgetSummaryView: View
    * **struct EditTransactionView: View
    * **struct TransactionCell: View
    * struct TransactionInputView: View
        * struct InputField: View
* struct AllCategoriesSummaryView: View
    * ***struct SummaryView: View
    * **struct TransactionCell: View
    * struct CategoryExpenseSummaryView: View
        * struct SummaryView: View
* struct TotalRepliesSummaryView: View
    * **struct EditTransactionView: View
    * **struct TransactionCell: View
    * struct ReplenishmentHeaderView: View
* struct SelectedCategoryDetailsView: View
    * **struct EditTransactionView: View
    * struct CategoryHeaderView: View

"**" означає, що структура використовується у багатьох головних структурах
"***" означає, що структура використовується у 1 головній структурі, але крім цього також використовується у підструктурі.
