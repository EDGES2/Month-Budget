Month Budget
│── Month Budget
│   ├── Backend
│   │   ├── Services
│   │   │   ├── Persistence.swift
│   │   ├── CoreData
│   │   │   ├── Month_Budget.xcdatamodeld
│   │   │   ├── Transaction+CoreDataClass.swift
│   │   │   ├── Transaction+CoreDataProperties.swift
│   ├── Frontend
│   │   ├── SideBar.swift
│   │   ├── TransactionsMainView.swift
│   │   ├── ContentView.swift
│   │   ├── Assets.xcassets
│   │   ├── Preview Content
│   │   │   ├── Media.xcassets
│   ├── Month_Budget.entitlements
│   ├── Month_BudgetApp.swift
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


git push -f origin HEAD
/usr/libexec/PlistBuddy -c "Add :MonobankToken string 'your-secret-token'" Config.plist

Опис імпортованих даних з Monobank API
Інформація про рахунок (/personal/client-info)

Ім'я клієнта (name): ПІБ власника рахунку.

Ідентифікатор клієнта (clientId): Унікальний ідентифікатор користувача.

Баланс рахунку (balance): Поточний баланс рахунку в копійках.

Типи рахунків (accounts): Масив об'єктів із деталями про рахунки (валюта, номер тощо).



Список транзакцій (/personal/statement/{account}/{from}/{to})

ID транзакції (id): Унікальний ідентифікатор операції.

Час транзакції (time): UNIX timestamp моменту здійснення операції.

Опис операції (description): Інформація про платіж (наприклад, назва магазину).

Сума операції (amount): Розмір операції у копійках (від’ємне значення для витрат).

Код валюти (currencyCode): ISO 4217 код валюти (наприклад, 980 – UAH).

Залишок після операції (balance): Баланс рахунку після здійснення операції.

Категорія транзакції (mcc): Код категорії торгової точки (Merchant Category Code).
