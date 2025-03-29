import Foundation

struct MonobankAPI {
    private let token = Config.getToken() ?? "" 
    private let baseURL = "https://api.monobank.ua"
    
    /// Отримати інформацію про рахунок (/personal/client-info)
    func fetchClientInfo(completion: @escaping (Result<Data, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/personal/client-info")!
        var request = URLRequest(url: url)
        // За документацією передаємо лише токен без префікса "Bearer"
        request.setValue(token, forHTTPHeaderField: "X-Token")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let httpResponse = response as? HTTPURLResponse {
                print("Status code:", httpResponse.statusCode)
                
                if let data = data {
                    print("Raw response data:", data)
                    print("Response string:", String(data: data, encoding: .utf8) ?? "nil")
                    completion(.success(data))
                } else {
                    let noDataError = NSError(domain: "MonobankAPI", code: -1, userInfo: [NSLocalizedDescriptionKey : "No data in response"])
                    completion(.failure(noDataError))
                }
            }
        }.resume()


    }
    
    /// Отримати список транзакцій за вказаний період (/personal/statement/{account}/{from}/{to})
    func fetchTransactions(from: TimeInterval, to: TimeInterval, completion: @escaping (Result<Data, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/personal/statement/0/\(Int(from))/\(Int(to))")!
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-Token")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                completion(.success(data))
            }
        }.resume()
    }
}
struct Config {
    static func getToken() -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return nil
        }
        return dict["MonobankToken"] as? String
    }
}

// Структура для декодування транзакцій із API
struct TransactionAPI: Codable {
    let id: String
    let time: Int
    let description: String
    let amount: Int
    let currencyCode: Int
    let balance: Int
    let category: Int  // Це поле фактично міститиме значення "mcc"

    enum CodingKeys: String, CodingKey {
        case id, time, description, amount, currencyCode, balance
        case category = "mcc"
    }
}


// Функція для тестування викликів API.
// Цей код потрібно викликати, наприклад, з SwiftUI .onAppear() або іншої відповідної точки запуску.
func testMonobankAPI() {
    let api = MonobankAPI()
    // Отримання інформації про рахунок
    api.fetchClientInfo { result in
        switch result {
        case .success(let data):
            if let json = String(data: data, encoding: .utf8) {
                print("Client Info: \(json)")
            }
        case .failure(let error):
            print("Error fetching client info: \(error.localizedDescription)")
        }
    }
    
    // Отримання транзакцій за останній місяць
    let oneMonthAgo = Date().timeIntervalSince1970 - (30 * 24 * 60 * 60)
    let now = Date().timeIntervalSince1970
    
    api.fetchTransactions(from: oneMonthAgo, to: now) { result in
        switch result {
        case .success(let data):
            if let json = String(data: data, encoding: .utf8) {
                print("Transactions JSON: \(json)")
            }
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let transactions = try decoder.decode([TransactionAPI].self, from: data)
                print("Decoded transactions: \(transactions)")
            } catch {
                print("JSON Decode Error: \(error.localizedDescription)")
            }
        case .failure(let error):
            print("Error fetching transactions: \(error.localizedDescription)")
        }
    }
}
