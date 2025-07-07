# Month Budget

## Opisanie dla CV
Ideą tego projektu była praktyczna nauka Swifta oraz SwiftUI. Stworzyłem tę aplikację na własne potrzeby, aby śledzić swój budżet. Nie jest jeszcze ukończona, ale obsługuje już tryb dwóch walut.

Oznacza to, że użytkownik wybiera jedną walutę jako główną (tę, której używa na co dzień) i drugą jako dodatkową. Jest to przydatne do śledzenia wydatków podczas pobytu w innym kraju. Aplikacja posiada wbudowany algorytm konwersji walut, który chroni przed błędami przy wydatkach w różnych walutach jednocześnie (w moim przypadku UAH, PLN, USD, EUR). Aplikacja korzysta również z API banku (Monobank).

## Project structure
```
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
```

## SideBar.swift
```
struct SidebarView: View
- struct Categories
    - struct ScaleButtonStyle: ButtonStyle
    - struct RenameCategory: View
    - struct CategoryMaker: View
```

## TransactionsMainView.swift
```
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
```

## ContentView.swift
```
struct MainAppView: View
extension Text
```

---

**Legend:**
- `~` means that the structure is used in many main structures.
- `''` means that the structure is used in one main structure, but also in its substructure.

---

git push -f origin HEAD
/usr/libexec/PlistBuddy -c "Add :MonobankToken string 'your-secret-token'" Config.plist

---

### Description of imported data from Monobank API

**Account Information (`/personal/client-info`)**

* **Client Name** (`name`): Full name of the account holder.
* **Client ID** (`clientId`): Unique user identifier.
* **Account Balance** (`balance`): Current account balance in kopecks.
* **Account Types** (`accounts`): An array of objects with account details (currency, number, etc.).

**Transaction List (`/personal/statement/{account}/{from}/{to}`)**

* **Transaction ID** (`id`): Unique transaction identifier.
* **Transaction Time** (`time`): UNIX timestamp of the transaction.
* **Transaction Description** (`description`): Information about the payment (e.g., store name).
* **Transaction Amount** (`amount`): The amount of the transaction in kopecks (a negative value for expenses).
* **Currency Code** (`currencyCode`): ISO 4217 currency code (e.g., 980 for UAH).
* **Balance After Transaction** (`balance`): The account balance after the transaction.
* **Transaction Category** (`mcc`): Merchant Category Code.

