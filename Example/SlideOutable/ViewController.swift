//
//  ViewController.swift
//  Scroller
//
//  Created by Domas Nutautas on 19/05/16.
//  Copyright © 2016 Domas Nutautas. All rights reserved.
//

import UIKit
import SlideOutable

class ViewController: UIViewController {

    var container: SlideOutable!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.removeFromSuperview()
        searchBar.removeFromSuperview()
        
        container = SlideOutable(frame: view.bounds, scroll: tableView, header: searchBar)
        container.delegate = self
        container.topPadding = 44
        
        container.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.addSubview(container)
    }
    
    let cells = ["Vilnius", "New York", "San Francisco", "Paris", "Berlin", "London", "Madrid", "Rome", "Mumbai", "Buenos Aires", "Oslo", "Helsinki"]
}

extension ViewController: SlideOutableDelegate {
    func slideOutable(slideOutable: SlideOutable, stateChanged state: SlideOutable.State) {
        let alpha: CGFloat
        switch state {
        case .settled(let position):
            switch position {
            case .expanded:
                alpha = 0.5
            default:
                alpha = 0
            }
        case .dragging(let offset):
            alpha = max(0, 0.5 * (200 - offset) / 200)
        }
        
        slideOutable.backgroundColor = UIColor(white: 0, alpha: alpha)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel?.text = cells[indexPath.row]
        return cell
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut,
                                   animations: { self.container.set(state: .expanded) },
                                   completion: nil)
    }
}
