//
//  DetailViewController.swift
//  ReceipeBrowser
//
//  Created by Andrii on 5/8/16.
//  Copyright © 2016 Andrii. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var receipeImageView: UIImageView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var showInWebButton: UIButton!
    @IBOutlet weak var tableView: UITableView!

    var tableData = [String](){
        didSet{
            tableView.reloadData()
        }
    }

    var receipe: AnyObject?

    func configureView(receipe:AnyObject) {
        if let imageData = receipe.valueForKey("image") as? NSData{
            receipeImageView.image = UIImage(data: imageData)
        } else {
            if let urlString = receipe.valueForKey("imageURL") as? String{
                receipeImageView.imageFromUrl(urlString)
            }
        }
        if let title = receipe.valueForKey("title") as? String{
            titleLabel.text = title
        }
        if let ingredients = receipe.valueForKey("ingredients") as? [String]{
            tableData = ingredients
        } else if let ingredientsString = receipe.valueForKey("ingredients") as? String{
            let ingredients = ingredientsString.characters.split{$0 == "~"}.map(String.init)
            tableData = ingredients
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadReceipeDetails()
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.allowsSelection = false
        saveButton.layer.cornerRadius = 5.0
        showInWebButton.layer.cornerRadius = 5.0
        checkSaveButton()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        view.setNeedsDisplay()
    }
    
    func checkSaveButton(){
        if let receipe = receipe{
            if let id = receipe.valueForKey("id") as? String{
                if Storage.sharedInstance.isReceipeStoredWithId(id){
                    saveButton.setTitle("Recipe Saved", forState: .Normal)
                    saveButton.setTitleColor(UIColor.greenColor(), forState: .Normal)
                    saveButton.enabled = false
                } else {
                    saveButton.setTitle("Save Recipe", forState: .Normal)
                    saveButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
                    saveButton.enabled = true
                }
            }
        }
        
    }
    
    @IBAction func saveAction(sender: UIButton) {
        guard let receipe = receipe as? TempReceipe else { return }
        guard Storage.sharedInstance.isReceipeStoredWithId(receipe.id) == false else { return }
        Storage.sharedInstance.saveTempReceipe(receipe) { (success) in
            if success{
                self.checkSaveButton()
            } else {
                DialogHelper.showOkAlertOnRootVC("failed to save recipe")
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")! as UITableViewCell
        let ingredient = tableData[indexPath.row]
        cell.textLabel?.text = ingredient
        return cell
    }
    
    func loadReceipeDetails(){
        if let receipe = receipe{
            if receipe.valueForKey("ingredients") == nil{
                guard let receipe = receipe as? TempReceipe else { DialogHelper.showOkAlertOnRootVC("Failed to get tempReceipe"); return }
                APIController.getIngredientsForTempReceipe(receipe) { (tempReceipe) in
                    if let tempReceipe = tempReceipe{
                        self.configureView(tempReceipe)
                    } else {
                        DialogHelper.showOkAlertOnRootVC("Failed to get ingredients")
                    }
                }
            } else {
                self.configureView(receipe)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "webVC"{
            if let webVC = segue.destinationViewController as? WebViewController{
                webVC.receipe = receipe
            }
        }
    }

    
}

