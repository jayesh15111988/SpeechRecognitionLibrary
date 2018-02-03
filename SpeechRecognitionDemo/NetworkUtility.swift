//
//  NetworkUtility.swift
//  SpeechRecognitionDemo
//
//  Created by Jayesh Kawli on 1/12/18.
//  Copyright © 2018 Jayesh Kawli. All rights reserved.
//

import Foundation
let baseURL = "https://translate.yandex.net/api/v1.5/tr.json/translate?key="
let apiKey = "trnsl.1.1.20180113T001452Z.8e43c71c88120ea4.ceea113be5031620a8cc81cf32f5db631d680907"

struct NetworkRequest {
    static func sendRequestWith(query: String, completion: @escaping (String) -> Void) {
        let urlString = baseURL + apiKey + "&text=\(query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")&lang=en-es"
        let encodedURLString = urlString
        let url = URL(string: encodedURLString)

        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            guard let data = data else {
                completion("")
                return
            }
            do {
                // Convert the data to JSON
                let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]

                if let json = jsonSerialized, let code = json["code"] as? Int, code == 200,  let translations = json["text"] as? [String], let bestTranslation = translations.first {
                    completion(bestTranslation)
                }
            }  catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
}
