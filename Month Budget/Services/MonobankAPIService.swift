// Month Budget/Services/MonobankAPIService.swift
import Foundation
import CoreData
import CryptoKit

struct MonobankAPIService {
    private let token = Config.getToken() ?? ""
    private let baseURL = "https://api.monobank.ua"
    
    func fetchClientInfo(completion: @escaping (Result<Data, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/personal/client-info")!
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-Token")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let httpResponse = response as? HTTPURLResponse, let data = data {
                print("Status code:", httpResponse.statusCode)
                completion(.success(data))
            } else {
                let noDataError = NSError(domain: "MonobankAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data in response"])
                completion(.failure(noDataError))
            }
        }.resume()
    }
    
    func fetchTransactions(from: TimeInterval, to: TimeInterval, completion: @escaping (Result<[APITransaction], Error>) -> Void) {
        let url = URL(string: "\(baseURL)/personal/statement/0/\(Int(from))/\(Int(to))")!
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-Token")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "MonobankAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let apiTransactions = try decoder.decode([APITransaction].self, from: data)
                completion(.success(apiTransactions))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    static func fetchAPITransactions(in context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            print("Не вдалося визначити початок місяця")
            return
        }
        
        let monobankAPI = MonobankAPIService()
        
        monobankAPI.fetchTransactions(from: startOfMonth.timeIntervalSince1970, to: now.timeIntervalSince1970) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let apiTransactions):
                    let currencyDataModel = CurrencyDataModel()
                    let currencyManager = CurrencyManager(currencyDataModel: currencyDataModel)
                    importAPITransactions(apiTransactions: apiTransactions, in: context, currencyManager: currencyManager)
                case .failure(let error):
                    print("Error fetching transactions: \(error.localizedDescription)")
                }
            }
        }
    }
    
    static func importAPITransactions(apiTransactions: [APITransaction], in context: NSManagedObjectContext, currencyManager: CurrencyManager) {
        var allTransactions: [Transaction] = []
        do {
            allTransactions = try context.fetch(Transaction.fetchRequest())
        } catch {
            print("Помилка отримання транзакцій: \(error.localizedDescription)")
        }
        
        apiTransactions.forEach { apiTxn in
            let apiUUID = UUID.uuidFromString(apiTxn.id)
            let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", apiUUID as CVarArg)
            
            if let count = try? context.count(for: fetchRequest), count > 0 {
                return
            }
            
            let newTransaction = Transaction(context: context)
            newTransaction.id = apiUUID
            newTransaction.firstCurrencyCode = currencyManager.baseCurrency1
            
            let amount = Double(apiTxn.amount) / 100.0
            let opAmount = Double(apiTxn.operationAmount) / 100.0
            
            newTransaction.date = Date(timeIntervalSince1970: TimeInterval(apiTxn.time))
            
            var convertedSecondAmount: Double = 0
            
            if let nearestTxn = currencyManager.nearestTransaction(from: currencyManager.baseCurrency1, to: currencyManager.baseCurrency2, forDate: newTransaction.date ?? Date(), transactions: allTransactions), nearestTxn.secondAmount != 0 {
                let rate = nearestTxn.firstAmount / nearestTxn.secondAmount
                convertedSecondAmount = amount / rate
            } else {
                convertedSecondAmount = opAmount
            }
            
            if amount > 0 {
                newTransaction.firstAmount = amount
                newTransaction.secondAmount = convertedSecondAmount
                newTransaction.category = "Поповнення"
            } else {
                newTransaction.firstAmount = abs(amount)
                newTransaction.secondAmount = abs(convertedSecondAmount)
                newTransaction.category = "API"
            }
            
            newTransaction.secondCurrencyCode = currencyManager.baseCurrency2
            newTransaction.comment = apiTxn.description
        }
        
        do {
            try context.save()
            print("API transactions imported successfully!")
        } catch {
            print("Error saving API transactions: \(error.localizedDescription)")
        }
    }
    
    static func deleteAllAPITransactions(in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", "API")

        do {
            let apiTransactions = try context.fetch(fetchRequest)

            for transaction in apiTransactions {
                context.delete(transaction)
            }

            try context.save()
            print("Успішно видалено \(apiTransactions.count) API транзакцій.")
        } catch {
            print("Помилка видалення API транзакцій: \(error.localizedDescription)")
        }
    }
}

struct Config {
    static func getToken() -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("Помилка: Не вдалося знайти або завантажити Config.plist")
            return nil
        }
        return dict["MonobankToken"] as? String
    }
}
