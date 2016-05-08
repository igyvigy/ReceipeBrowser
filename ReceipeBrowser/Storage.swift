//
//  Storage.swift
//  ReceipeBrowser
//
//  Created by Andrii on 5/8/16.
//  Copyright © 2016 Andrii. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Storage:NSObject{
    
    var controller:NSFetchedResultsController!
    
    class var sharedInstance: Storage {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: Storage? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = Storage()
        }
        return Static.instance!
    }
    
    func instanitiateReceipeControllerWithDelegate(context:NSManagedObjectContext ,delegate:NSFetchedResultsControllerDelegate){
        let fetchRequest = NSFetchRequest(entityName: "Receipe")
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: "Master")
        controller.delegate = delegate
        fetch()
    }

    func fetch() {
        do{
            try controller.performFetch()
        } catch { print (error) }
    }
    
    func deleteReceipeForIndexPath(indexPath:NSIndexPath) throws {
        let context = controller.managedObjectContext
        context.deleteObject(controller.objectAtIndexPath(indexPath) as! NSManagedObject)
        do {
            try context.save()
        } catch {
            throw error
        }
    }
    
    func saveTempReceipe(tempReceipe:TempReceipe, completion:(success:Bool) -> ()) {
        if let ingredients = tempReceipe.ingredients{
            let ingredientsStringRepresentation = ingredients.joinWithSeparator("~")
            
            if let url = NSURL(string: tempReceipe.imageURL){
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    if let imageData = NSData(contentsOfURL: url){
                        dispatch_async(dispatch_get_main_queue(), {
                            var receipe:Receipe!
                            receipe = NSEntityDescription.insertNewObjectForEntityForName("Receipe", inManagedObjectContext: self.controller.managedObjectContext) as! Receipe
                            receipe.title = tempReceipe.title
                            receipe.sourceURL = tempReceipe.sourceURL
                            receipe.socialRank = tempReceipe.socialRank
                            receipe.id = tempReceipe.id
                            receipe.publisherURL = tempReceipe.publisherURL
                            receipe.publisher = tempReceipe.publisher
                            receipe.imageURL = tempReceipe.imageURL
                            receipe.f2fURL = tempReceipe.f2fURL
                            receipe.category = tempReceipe.category
                            receipe.ingredients = ingredientsStringRepresentation
                            receipe.image = imageData
                            
                            do{
                                try self.controller.managedObjectContext.save()
                                print("\(tempReceipe.title) saved")
                                completion(success: true)
                            } catch {
                                completion(success: false)
                            }
                        })
                    } else {
                        completion(success: false)
                    }
                }
            } else {
                completion(success: false)
            }
        } else {
            completion(success: false)
        }
    }
    
    func isReceipeStoredWithId(id:String) -> Bool{
        let storedReceipes = controller.fetchedObjects as! [Receipe]
        return storedReceipes.filter({$0.id == id}).count > 0
    }
    
}