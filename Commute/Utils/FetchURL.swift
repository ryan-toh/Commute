//
//  FetchURL.swift
//  Commute
//
//  Created by Ryan on 4/7/26.
//

import Foundation

extension URLSession {
    func fetchData<T:Decodable>(at url: URL, completion: @escaping (Result<T, Error>) -> Void) {
        
    self.dataTask(with: url) { (data, response, error) in
      if let error = error {
        completion(.failure(error))
      }

      if let data = data {
        do {
          let response = try JSONDecoder().decode(T.self, from: data)
          completion(.success(response))
        } catch let decoderError {
          completion(.failure(decoderError))
        }
      }
    }.resume()
  }
}
