//
//  LocationSettingsTableViewController.swift
//  tpg offline
//
//  Created by Alice on 11/01/2016.
//  Copyright © 2016 dacostafaro. All rights reserved.
//

import UIKit
import SwiftyJSON
import ChameleonFramework
import FontAwesomeKit

class LocationSettingsTableViewController: UITableViewController {

    let defaults = NSUserDefaults.standardUserDefaults()
    let headers = ["Précision", "Distance de proximité d'arrets"]
    let choices = [["Normale", "Précise", "Très précise"], ["100m", "200m", "500m", "750m", "1km"]]
    let values = [[0, 1, 2], [100, 200, 500, 750, 1000]]
    var rowSelected = [0,0]
    override func viewDidLoad() {
        super.viewDidLoad()
        rowSelected[0] = values[0].indexOf(defaults.integerForKey("locationAccurency"))!
        if defaults.integerForKey("proximityDistance") == 0 {
            defaults.setInteger(500, forKey: "proximityDistance")
        }
        rowSelected[1] = values[1].indexOf(defaults.integerForKey("proximityDistance"))!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return choices[section].count
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("choixTabDefaultCell", forIndexPath: indexPath)
        
        cell.textLabel?.text = choices[indexPath.section][indexPath.row]
        cell.selectionStyle = .None
        if indexPath.row == rowSelected[indexPath.section] {
            let iconOk = FAKFontAwesome.checkIconWithSize(20)
            iconOk.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
            cell.accessoryView = UIImageView(image: iconOk.imageWithSize(CGSize(width: 20, height: 20)))
        }
        else {
            cell.accessoryView = nil
        }
        
        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            defaults.setInteger(values[0][indexPath.row], forKey: "locationAccurency")
        }
        else {
            defaults.setInteger(values[1][indexPath.row], forKey: "proximityDistance")
        }
        rowSelected[indexPath.section] = indexPath.row
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        tableView.reloadData()
    }
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let returnedView = UIView()
        returnedView.backgroundColor = UIColor.flatOrangeColorDark()
        
        let label = UILabel(frame: CGRect(x: 20, y: 5, width: 500, height: 30))
        label.text = headers[section]
        label.textColor = UIColor.whiteColor()
        returnedView.addSubview(label)
        
        return returnedView
    }
}
