Month Budget
│── Month Budget
│   │── Backend
│   │   │── Services
│   │   │   │── Persistence.swift
│   │   │── CoreData
│   │   │   │── Month_Budget.xcdatamodeld
│   │   │   │── Transaction+CoreDataClass.swift
│   │   │   │── Transaction+CoreDataProperties.swift
│   │── Frontend
│   │   │── SideBar.swift
│   │   │── TransactionsMainView.swift
│   │   │── ContentView.swift
│   │   │── Assets.xcassets
│   │   │── Preview Content
│   │   │   │── Media.xcassets
│   │── Month_Budget.entitlements
│   │── Month_BudgetApp.swift
│── Month BudgetTests
│── Month BudgetUITests
│── Products
│── README.md

_______________________________________________________

SideBar.swift
struct SidebarView: View
- struct Categories
    - struct ScaleButtonStyle: ButtonStyle
    - struct RenameCategory: View
    - struct CategoryMaker: View
_______________________________________________________

TransactionsMainView.swift:
struct TransactionsMainView: View
- struct BudgetSummaryListView: View
    - struct BudgetSummaryView: View
    - ~struct EditTransactionView: View
    - ~struct TransactionCell: View
    - struct TransactionInput: View
        - struct InputField: View
- struct AllCategoriesSummaryView: View
    - struct CategoryExpenseSummary: View
    - struct SummaryView: View
    - ``struct SummaryView: View
    - ~struct TransactionCell: View
- struct TotalRepliesSummaryView: View
    - ~struct EditTransactionView: View
    - ~struct TransactionCell: View
    - struct ReplenishmentHeader: View
- struct SelectedCategoryDetailsView: View
    - ~struct EditTransactionView: View
    - struct CategoryHeader: View
_______________________________________________________

ContentView.swift:
struct MainAppView: View
extension Text
_______________________________________________________





"~" означає, що структура використовується у багатьох головних структурах
"``" означає, що структура використовується у 1 головній структурі, але крім цього також використовується у підструктурі.
