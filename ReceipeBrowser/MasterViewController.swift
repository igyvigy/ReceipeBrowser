//
//  MasterViewController.swift
//  ReceipeBrowser
//
//  Created by Andrii on 5/8/16.
//  Copyright © 2016 Andrii. All rights reserved.
//

import UIKit
import CoreData

enum State{
    case Stored
    case Browse
}

class MasterViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource{

    let searchController = UISearchController(searchResultsController: nil), scopeTitles = ["Top Rated", "Trending"]
    
    var detailViewController: DetailViewController? = nil, fetchedResultsController: NSFetchedResultsController!, refreshControl:UIRefreshControl!, state:State!, filteredReceipes = [Receipe](), currentPage = 1, currentSearch = "", currentSorting:SearchSorting = .Rating
    
    var tempReceipes = [TempReceipe](){
        didSet{
            tableView.reloadData()
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var switcher: UISegmentedControl!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
// MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        state = .Stored
        setTitle()
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        // Setup refresh control
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(MasterViewController.refresh), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        
        // Setup the Scope Bar
        searchController.searchBar.scopeButtonTitles = scopeTitles
        tableView.tableHeaderView = searchController.searchBar
        
        fetchedResultsController = Storage.sharedInstance.controller
        activityIndicator.stopAnimating()
        
        tableView.estimatedRowHeight = 114
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        checkState()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

// MARK: - Prepare For Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                var object:AnyObject
                switch state! {
                case .Stored:
                    if searchController.active && searchController.searchBar.text != "" {
                        object = filteredReceipes[indexPath.row]
                    } else {
                        object = fetchedResultsController.objectAtIndexPath(indexPath) as! Receipe
                    }
                case .Browse:
                    object = tempReceipes[indexPath.row]
                }
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
            controller.receipe = object
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
            controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

// MARK: - Table View

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
        
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch state! {
        case .Stored:
            if searchController.active && searchController.searchBar.text != "" {
                return filteredReceipes.count
            }
            return Storage.sharedInstance.controller.fetchedObjects?.count ?? 0
        case .Browse:
            return tempReceipes.count
        }
        
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ReceipeCell") as! ReceipeCell
        cell.recImageView.image = UIImage(named: "search")
        switch state! {
        case .Stored:
            var receipe:Receipe
            if searchController.active && searchController.searchBar.text != "" {
                receipe = filteredReceipes[indexPath.row]
            } else {
                receipe = fetchedResultsController.objectAtIndexPath(indexPath) as! Receipe
            }
            cell.configureWithReceipe(receipe)
        case .Browse:
            let tempReceipe = tempReceipes[indexPath.row]
            cell.configureWithReceipe(tempReceipe)
        }
        return cell
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if state! == .Stored{
            return true
        } else {
            return false
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            do{
                try Storage.sharedInstance.deleteReceipeForIndexPath(indexPath)
            } catch { print(error) }
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if state! == .Browse{
            if indexPath.row == (tempReceipes.count - 1) {
                currentPage += 1
                loadTempReceipes(currentSearch, sorting: currentSorting)
            }
        }
    }

// MARK: - NSFetchedResultsControllerDelegate Methods
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        if state! == .Stored{
            self.tableView.beginUpdates()
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        if state! == .Stored{
            switch type {
                case .Insert:
                    self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
                case .Delete:
                    self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
                default:
                    return
            }
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if state! == .Stored{
            switch type {
                case .Insert:
                    tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
                case .Delete:
                    tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                case .Update:
                    let cell = tableView.cellForRowAtIndexPath(indexPath!) as! ReceipeCell
                    cell.configureWithReceipe(anObject)
                case .Move:
                    tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
            }
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if state! == .Stored{
            self.tableView.endUpdates()
        }
    }


     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
//     func controllerDidChangeContent(controller: NSFetchedResultsController) {
//         // In the simplest, most efficient, case, reload the table view.
//         tableView.reloadData()
//     }
 
// MARK: - Utility Methods
    
    func filterContentForSearchText(searchText: String, scope: String = "r") {
        if let storedReceipes = Storage.sharedInstance.controller.fetchedObjects as? [Receipe]{
            filteredReceipes = storedReceipes.filter({( receipe:Receipe) -> Bool in
                let categoryMatch = (receipe.category == scope)
                return categoryMatch && receipe.title.lowercaseString.containsString(searchText.lowercaseString)
            })
        }
        tableView.reloadData()
    }

    func refresh(){
        switch state!{
        case .Stored:
            Storage.sharedInstance.fetch()
            self.refreshControl?.endRefreshing()
        case .Browse:
            currentPage = 1
            loadTempReceipes(currentSearch, sorting: currentSorting)
        }
    }
    
    func setTitle(){
        switch state!{
        case State.Stored:
            title = "Stored Recipes"
        case State.Browse:
            title = "Browse Recipes"
        }
    }
    
    func checkIfStorageIsEmpty(){
        if Storage.sharedInstance.controller.fetchedObjects?.count == 0{
            DialogHelper.showAlert("No stored recipes yet", message: "Search for recipes on (Browse) tab and hit (Save Recipe) button for them to appear on this list", buttonTitles: ["Got It"], actions: [{
                self.switcher.selectedSegmentIndex = 1
                self.state! = .Browse
                self.performStateSwitching()
                self.searchController.active = true
                }], delegate: self)
        }
    }
    
    func checkIfBrowseIsEmpty(){
        if tempReceipes.count == 0{
            self.searchController.active = true
            self.currentPage = 1
            self.currentSearch = ""
            self.currentSorting = SearchSorting.Rating
            self.loadTempReceipes("", sorting: SearchSorting.Rating)
        }
    }
    
    func checkState(){
        switch state!{
        case State.Stored:
            checkIfStorageIsEmpty()
        case State.Browse:
            checkIfBrowseIsEmpty()
        }
    }
    
    func performStateSwitching(){
        setTitle()
        tableView.reloadData()
        searchController.active = false
        checkState()
    }
    
    @IBAction func switcherSwitched(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            state! = .Stored
            performStateSwitching()
        } else {
            state! = .Browse
            performStateSwitching()
        }
    }
    
    
// MARK: - API search
    
    func loadTempReceipes(searchString:String = "", sorting:SearchSorting = .Rating){
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        APIController.searchReceipesWithSearchQuery(searchString, sorting: sorting, page: currentPage){tempReceipes in
            self.activityIndicator.stopAnimating()
            if let tempReceipes = tempReceipes{
                if self.currentPage == 1{
                    self.tempReceipes = tempReceipes
                } else {
                    self.tempReceipes.appendContentsOf(tempReceipes)
                }
            }
            if self.refreshControl.refreshing{
                self.refreshControl.endRefreshing()
            }
        }
    }

}

// MARK: - UISearchBar Delegate

extension MasterViewController: UISearchBarDelegate {
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        switch state!{
        case .Stored:
            filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope] == scopeTitles[0] ? "r" : "t")
        case .Browse:
            let sorting = SearchSorting.searchSortingWithString(searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex] == scopeTitles[0] ? "r" : "t")
            self.currentPage = 1
            self.currentSearch = ""
            searchBar.text = ""
            self.currentSorting = sorting
            self.loadTempReceipes("", sorting: sorting)
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        let sorting = SearchSorting.searchSortingWithString(searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex] == scopeTitles[0] ? "r" : "t")
        let searchString = searchBar.text != nil ? searchBar.text! : ""
        switch self.state!{
        case .Stored:
            self.filterContentForSearchText(searchString, scope: sorting.rawValue)
        case .Browse:
            if searchString == currentSearch {} else {
                self.currentPage = 1
                self.currentSearch = searchString
                self.loadTempReceipes(searchString, sorting: SearchSorting.Rating)
            }
        }
    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        if state! == .Browse{
            if currentSearch != ""{
                searchBar.text = currentSearch
            }
        }
        return true
    }
    
}
// MARK: - UISearchResultsUpdating Delegate

extension MasterViewController: UISearchResultsUpdating {
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex] == scopeTitles[0] ? "r" : "t"
        filterContentForSearchText(searchController.searchBar.text!, scope: scope)
    }
}
