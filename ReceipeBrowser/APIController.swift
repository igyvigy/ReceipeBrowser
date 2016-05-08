//
//  APIController.swift
//  ReceipeBrowser
//
//  Created by Andrii on 5/8/16.
//  Copyright © 2016 Andrii. All rights reserved.
//

import Foundation
import UIKit

class APIController{
    
    static let ApiKey = "5ea6ccb4d0aa9da8aea7657971a2bedd", ApiSearchURL = "http://food2fork.com/api/search", ApiReceipeURL = "http://food2fork.com/api/get"
    
    static func sendRequest(url: String, parameters: [String: AnyObject], completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionTask {
        let parameterString = parameters.stringFromHttpParameters()
        let requestURL = NSURL(string:"\(url)?\(parameterString)")!
        let request = NSMutableURLRequest(URL: requestURL)
        request.HTTPMethod = "GET"
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler:completionHandler)
        task.resume()
        
        return task
    }
    
    static func searchReceipesWithSearchQuery(searchQuery:String, sorting:SearchSorting = .Rating, page:Int = 1, completion:([TempReceipe]?) -> ()){
        let params = [
            "key":ApiKey,
            "q":searchQuery,
            "sort":sorting.rawValue,
            "page":"\(page)"
        ]
        sendRequest(ApiSearchURL, parameters: params as [String:AnyObject]) { (data, response, error) in
            if let error = error{
                print(error.localizedDescription)
                completion(nil)
            } else if let data = data{
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as! [String:AnyObject]
                    guard let count = json["count"] as? Int, receipes = json["recipes"] as? [[String:AnyObject]] else { completion(nil); return }
                    dispatch_async(dispatch_get_main_queue(), {
                        if count > 0 {
                            var tempReceipes = [TempReceipe]()
                            receipes.forEach({ (dataDict) in
                                tempReceipes.append(TempReceipe(dataDict: dataDict, category: sorting.rawValue))
                            })
                            completion(tempReceipes)
                        } else {
                            if page == 1{
                                DialogHelper.showOkAlertOnRootVC("no results matched query")
                            }
                            completion(nil)
                        }
                    })
                    
                } catch {
                    print("error serializing JSON: \(error)")
                    completion(nil)
                }
            }
        }
    }
    
    static func getIngredientsForTempReceipe(receipe:TempReceipe, completion:(AnyObject?) -> ()){
        let params = [
            "key":ApiKey,
            "rId":receipe.id,
        ]
        sendRequest(ApiReceipeURL, parameters: params as [String:AnyObject]) { (data, response, error) in
            if let error = error{
                print(error.localizedDescription)
                completion(nil)
            } else if let data = data{
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as! [String:AnyObject]
                    guard let dict = json["recipe"] as? [String:AnyObject] else { completion(nil); return}
                    guard let ingredients = dict["ingredients"] as? [String]  else { completion(nil); return}
                    dispatch_async(dispatch_get_main_queue(), {
                        receipe.ingredients = ingredients
                        completion(receipe)
                    })
                } catch {
                    print("error serializing JSON: \(error)")
                    completion(nil)
                }
            }
        }
    }
}

enum SearchSorting:String{
    case Rating = "r"
    case Trend = "t"
    
    static func searchSortingWithString(string:String) -> SearchSorting{
        switch string{
        case "r": return .Rating
        case "t": return .Trend
        default: return .Rating
        }
    }
}

extension UIImageView {
    func imageFromUrl(url:String, contentMode mode: UIViewContentMode = .ScaleAspectFill) {
        guard
            let url = NSURL(string: url)
            else {return}
        contentMode = mode
        NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, response, error) -> Void in
            guard
                let httpURLResponse = response as? NSHTTPURLResponse where httpURLResponse.statusCode == 200,
                let mimeType = response?.MIMEType where mimeType.hasPrefix("image"),
                let data = data where error == nil,
                let image = UIImage(data: data)
                else { return }
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.image = image
            }
        }).resume()
    }
}



extension String {
    func stringByAddingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return self.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)
    }
}

extension Dictionary {
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            let percentEscapedKey = (key as! String).stringByAddingPercentEncodingForURLQueryValue()!
            let percentEscapedValue = (value as! String).stringByAddingPercentEncodingForURLQueryValue()!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        return parameterArray.joinWithSeparator("&")
    }
}