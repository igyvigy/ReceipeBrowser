//
//  Receipe+TempReceipe.swift
//  ReceipeBrowser
//
//  Created by Andrii on 5/8/16.
//  Copyright © 2016 Andrii. All rights reserved.
//
//

import Foundation
import CoreData

class Receipe: NSManagedObject {
    @NSManaged var title: String
    @NSManaged var sourceURL: String
    @NSManaged var socialRank: NSNumber
    @NSManaged var id: String
    @NSManaged var publisherURL: String
    @NSManaged var publisher: String
    @NSManaged var imageURL: String
    @NSManaged var f2fURL: String
    @NSManaged var category: String
    @NSManaged var ingredients: String
    @NSManaged var image: NSData?
}

class TempReceipe:NSObject{
    let title: String
    let sourceURL: String
    let socialRank: NSNumber
    let id: String
    let publisherURL: String
    let publisher: String
    let imageURL: String
    let f2fURL: String
    let category: String
    var ingredients: [String]?
    var image:NSData?
    
    init (title: String, sourceURL: String, socialRank: NSNumber, id: String, publisherURL: String, publisher: String, imageURL: String, f2fURL: String, category: String){
        self.title = title
        self.sourceURL = sourceURL
        self.socialRank = socialRank
        self.id = id
        self.publisherURL = publisherURL
        self.publisher = publisher
        self.imageURL = imageURL
        self.f2fURL = f2fURL
        self.category = category
    }
    
    init (dataDict: [String:AnyObject], category:String){
        let title = dataDict["title"] as! String,
        sourceURL = dataDict["source_url"] as! String,
        socialRank = dataDict["social_rank"] as! NSNumber,
        id = dataDict["recipe_id"] as! String,
        publisherURL = dataDict["publisher_url"] as! String,
        publisher = dataDict["publisher"] as! String,
        imageURL = dataDict["image_url"] as! String,
        f2fURL = dataDict["f2f_url"] as! String

        self.title = title
        self.sourceURL = sourceURL
        self.socialRank = socialRank
        self.id = id
        self.publisherURL = publisherURL
        self.publisher = publisher
        self.imageURL = imageURL
        self.f2fURL = f2fURL
        self.category = category
        
    }
}
