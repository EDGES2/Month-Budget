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
