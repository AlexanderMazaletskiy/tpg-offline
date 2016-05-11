//
//  ListeItinerairesTableViewController.swift
//  tpg offline
//
//  Created by Rémy Da Costa Faro on 19/01/2016.
//  Copyright © 2016 dacostafaro. All rights reserved.
//

import UIKit
import SwiftyJSON
import ChameleonFramework
import FontAwesomeKit
import SCLAlertView
import MRProgress
import SwiftDate
import Alamofire

class ListeItinerairesTableViewController: UITableViewController {
    
    let defaults = NSUserDefaults.standardUserDefaults()
    var favoris = false
    var pasReseau = false
    var chargement = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ItineraireEnCours.itineraireResultat = []
        tableView.backgroundColor = AppValues.primaryColor
        
        if ItineraireEnCours.itineraire.depart != nil && ItineraireEnCours.itineraire.arrivee != nil && ItineraireEnCours.itineraire.date != nil {
            chargement = true
            refresh()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        actualiserTheme()
        
        tableView.backgroundColor = AppValues.primaryColor
        
        if ItineraireEnCours.itineraire.depart != nil && ItineraireEnCours.itineraire.arrivee != nil && ItineraireEnCours.itineraire.date != nil {
            var listeItems: [UIBarButtonItem] = []
            
            if (AppValues.premium == true) {
                for x in AppValues.favorisItineraires {
                    if x[0].nomComplet == ItineraireEnCours.itineraire.depart?.nomComplet && x[1].nomComplet == ItineraireEnCours.itineraire.arrivee?.nomComplet {
                        favoris = true
                        break
                    }
                }
                if favoris {
                    listeItems.append(UIBarButtonItem(image: FAKFontAwesome.starIconWithSize(20).imageWithSize(CGSize(width: 20,height: 20)), style: UIBarButtonItemStyle.Done, target: self, action: #selector(ListeItinerairesTableViewController.toggleFavorite(_:))))
                }
                else {
                    listeItems.append(UIBarButtonItem(image: FAKFontAwesome.starOIconWithSize(20).imageWithSize(CGSize(width: 20,height: 20)), style: UIBarButtonItemStyle.Done, target: self, action: #selector(ListeItinerairesTableViewController.toggleFavorite(_:))))
                }
            }
            self.navigationItem.rightBarButtonItems = listeItems
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if chargement == true {
            return 1
        }
        else if ItineraireEnCours.itineraire == nil {
            return 0
        }
        else if ItineraireEnCours.itineraire.depart == nil || ItineraireEnCours.itineraire.arrivee == nil || ItineraireEnCours.itineraire.date == nil {
            return 0
        }
        else if pasReseau {
            return 1
        }
        else if ItineraireEnCours.itineraireResultat.count == 0 {
            return 1
        }
        else {
            return ItineraireEnCours.itineraireResultat.count
        }
    }
    
    func refresh() {
        chargement = true
        tableView.reloadData()
        let parameters = [
            "key": "d95be980-0830-11e5-a039-0002a5d5c51b",
            "from": ItineraireEnCours.itineraire.depart!.idTransportAPI,
            "to": ItineraireEnCours.itineraire.arrivee!.idTransportAPI,
            "date": String(ItineraireEnCours.itineraire.date!.year) + "-" + String(ItineraireEnCours.itineraire.date!.month) + "-" + String(ItineraireEnCours.itineraire.date!.day),
            "time": String(ItineraireEnCours.itineraire.date!.hour) + ":" + String(ItineraireEnCours.itineraire.date!.minute),
            "isArrivalTime": String(Int(ItineraireEnCours.itineraire.dateArrivee))
        ]
        
        ItineraireEnCours.itineraireResultat = []
        Alamofire.request(.GET, "http://transport.opendata.ch/v1/connections", parameters: parameters).responseJSON { response in
            if let data = response.result.value {
                let json = JSON(data)
                for (_, subJSON) in json["connections"] {
                    var correspondances: [ItineraireCorrespondances] = []
                    for (_, subJSON2) in subJSON["sections"] {
                        if subJSON2["walk"].type == .Null {
                            correspondances.append(ItineraireCorrespondances(
                                ligne: subJSON2["journey"]["name"].stringValue.characters.split(" ").map(String.init)[1],
                                isTpg: (subJSON2["journey"]["operator"].stringValue == "TPG"),
                                isSBB: (subJSON2["journey"]["operator"].stringValue == "SBB"),
                                categorie: subJSON2["journey"]["categoryCode"].intValue,
                                de: subJSON2["departure"]["station"]["name"].stringValue,
                                a: subJSON2["arrival"]["station"]["name"].stringValue,
                                direction: subJSON2["journey"]["to"].stringValue,
                                timestampDepart: subJSON2["departure"]["departureTimestamp"].intValue,
                                timestampArrivee: subJSON2["arrival"]["arrivalTimestamp"].intValue
                                ))
                        }
                        else {
                            correspondances.append(
                                ItineraireCorrespondances(
                                    isWalk: true,
                                    de: subJSON2["departure"]["station"]["name"].stringValue,
                                    a: subJSON2["arrival"]["station"]["name"].stringValue,
                                    timestampDepart: subJSON2["departure"]["departureTimestamp"].intValue,
                                    timestampArrivee: subJSON2["arrival"]["arrivalTimestamp"].intValue,
                                    direction: subJSON2["walk"]["duration"].stringValue.characters.split(":").map(String.init)[1] + " minute(s)".localized()
                                )
                            )
                        }
                    }
                    var dureeString = subJSON["duration"].stringValue
                    dureeString.removeRange(dureeString.startIndex..<dureeString.startIndex.advancedBy(3))
                    ItineraireEnCours.itineraireResultat.append(
                        Itineraire(
                            de: subJSON["from"]["station"]["name"].stringValue,
                            a: subJSON["to"]["station"]["name"].stringValue,
                            duree: dureeString,
                            timestampDepart: subJSON["from"]["departureTimestamp"].intValue,
                            timestampArrivee: subJSON["to"]["arrivalTimestamp"].intValue,
                            correspondances: correspondances
                        )
                    )
                }
                self.chargement = false
                self.tableView.reloadData()
            }
            else {
                self.pasReseau = true
                self.chargement = false
                self.tableView.allowsSelection = false
                self.tableView.reloadData()
            }
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if chargement == true {
            let cell = tableView.dequeueReusableCellWithIdentifier("loadingCell", forIndexPath: indexPath) as! loadingCellTableViewCell
            
            if ContrastColorOf(AppValues.primaryColor, returnFlat: true) == FlatWhite() {
                cell.backgroundColor = UIColor.flatBlueColor()
                cell.titleLabel?.textColor = UIColor.whiteColor()
                cell.subTitleLabel?.textColor = UIColor.whiteColor()
                cell.activityIndicator.color = UIColor.whiteColor()
            }
            else {
                cell.backgroundColor = UIColor.whiteColor()
                cell.titleLabel?.textColor = UIColor.flatBlueColor()
                cell.subTitleLabel?.textColor = UIColor.flatBlueColor()
                cell.activityIndicator.color = UIColor.flatBlueColor()
            }
            cell.titleLabel?.text = "Chargement".localized()
            cell.subTitleLabel?.text = "Merci de patienter".localized()
            cell.accessoryView = nil
            
            cell.activityIndicator.startAnimation()
            
            return cell
        }
            
        else if pasReseau {
            let cell = tableView.dequeueReusableCellWithIdentifier("listeItineaireCell", forIndexPath: indexPath) as! ListeItinerairesTableViewCell
            if ContrastColorOf(AppValues.primaryColor, returnFlat: true) == FlatWhite() {
                cell.textLabel?.textColor = UIColor.whiteColor()
                cell.detailTextLabel?.textColor = UIColor.whiteColor()
                cell.backgroundColor = UIColor.flatRedColorDark()
                
                let iconeError = FAKFontAwesome.timesCircleIconWithSize(20)
                iconeError.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
                cell.imageView?.image = iconeError.imageWithSize(CGSize(width: 25, height: 25))
            }
            else {
                cell.textLabel?.textColor = UIColor.flatRedColorDark()
                cell.detailTextLabel?.textColor = UIColor.flatRedColorDark()
                cell.backgroundColor = UIColor.flatWhiteColor()
                
                let iconeError = FAKFontAwesome.timesCircleIconWithSize(20)
                iconeError.addAttribute(NSForegroundColorAttributeName, value: UIColor.flatRedColorDark())
                cell.imageView?.image = iconeError.imageWithSize(CGSize(width: 25, height: 25))
            }
            
            cell.textLabel?.text = "Pas de réseau".localized()
            
            return cell
        }
            
        else if ItineraireEnCours.itineraireResultat.count == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("listeItineaireCell", forIndexPath: indexPath) as! ListeItinerairesTableViewCell
            if ContrastColorOf(AppValues.primaryColor, returnFlat: true) == FlatWhite() {
                cell.textLabel?.textColor = UIColor.whiteColor()
                cell.detailTextLabel?.textColor = UIColor.whiteColor()
                cell.backgroundColor = UIColor.flatRedColorDark()
                
                let iconeError = FAKFontAwesome.timesCircleIconWithSize(20)
                iconeError.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
                cell.imageView?.image = iconeError.imageWithSize(CGSize(width: 25, height: 25))
            }
            else {
                cell.textLabel?.textColor = UIColor.flatRedColorDark()
                cell.detailTextLabel?.textColor = UIColor.flatRedColorDark()
                cell.backgroundColor = UIColor.flatWhiteColor()
                
                let iconeError = FAKFontAwesome.timesCircleIconWithSize(20)
                iconeError.addAttribute(NSForegroundColorAttributeName, value: UIColor.flatRedColorDark())
                cell.imageView?.image = iconeError.imageWithSize(CGSize(width: 25, height: 25))
            }
            
            cell.textLabel?.text = "Itinéraires non trouvés".localized()
            
            return cell
        }
            
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier("listeItineaireCell", forIndexPath: indexPath) as! ListeItinerairesTableViewCell
            cell.textLabel?.text = nil
            cell.imageView?.image = nil
            var icone = FAKIonIcons.logOutIconWithSize(21)
            icone.addAttribute(NSForegroundColorAttributeName, value: AppValues.textColor)
            
            var attributedString = NSMutableAttributedString(attributedString: icone.attributedString())
            attributedString.appendAttributedString(NSAttributedString(string: " " + ItineraireEnCours.itineraireResultat[indexPath.row].de))
            cell.labelDepart.attributedText = attributedString
            cell.labelDepart.textColor = AppValues.textColor
            
            icone = FAKIonIcons.logInIconWithSize(21)
            icone.addAttribute(NSForegroundColorAttributeName, value: AppValues.textColor)
            
            attributedString = NSMutableAttributedString(attributedString: icone.attributedString())
            attributedString.appendAttributedString(NSAttributedString(string: " " + ItineraireEnCours.itineraireResultat[indexPath.row].a))
            cell.labelArrivee.attributedText = attributedString
            cell.labelArrivee.textColor = AppValues.textColor
            
            icone = FAKIonIcons.clockIconWithSize(21)
            icone.addAttribute(NSForegroundColorAttributeName, value: AppValues.textColor)
            
            attributedString = NSMutableAttributedString(attributedString: icone.attributedString())
            attributedString.appendAttributedString(NSAttributedString(string: " " + ItineraireEnCours.itineraireResultat[indexPath.row].duree))
            cell.labelDuree.attributedText = attributedString
            cell.labelDuree.textColor = AppValues.textColor
            
            var timestamp = ItineraireEnCours.itineraireResultat[indexPath.row].timestampDepart
            cell.labelHeureDepart.text = NSDateFormatter.localizedStringFromDate(NSDate(timeIntervalSince1970: Double(timestamp)), dateStyle: NSDateFormatterStyle.NoStyle, timeStyle: NSDateFormatterStyle.ShortStyle)
            cell.labelHeureDepart.textColor = AppValues.textColor
            
            timestamp = ItineraireEnCours.itineraireResultat[indexPath.row].timestampArrivee
            cell.labelHeureArrivee.text = NSDateFormatter.localizedStringFromDate(NSDate(timeIntervalSince1970: Double(timestamp)), dateStyle: NSDateFormatterStyle.NoStyle, timeStyle: NSDateFormatterStyle.ShortStyle)
            cell.labelHeureArrivee.textColor = AppValues.textColor
            
            cell.backgroundColor = AppValues.primaryColor
            
            let view = UIView()
            view.backgroundColor = AppValues.secondaryColor
            cell.selectedBackgroundView = view
            
            return cell
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "voirItineraire" {
            let destinationViewController: VueItineraireTableViewController = (segue.destinationViewController) as! VueItineraireTableViewController
            destinationViewController.compteur = (tableView.indexPathForSelectedRow?.row)!
        }
    }
    func toggleFavorite(sender: AnyObject!) {
        if AppValues.favorisItineraires.isEmpty {
            AppValues.favorisItineraires = [[ItineraireEnCours.itineraire.depart!, ItineraireEnCours.itineraire.arrivee!]]
        }
        else {
            if self.favoris {
                AppValues.favorisItineraires = AppValues.favorisItineraires.filter({ (arretA) -> Bool in
                    if arretA[0].nomComplet == ItineraireEnCours.itineraire.depart?.nomComplet && arretA[1].nomComplet == ItineraireEnCours.itineraire.arrivee?.nomComplet {
                        return false
                    }
                    return true
                })
            }
            else {
                AppValues.favorisItineraires.append([ItineraireEnCours.itineraire.depart!, ItineraireEnCours.itineraire.arrivee!])
            }
        }
        
        self.favoris = !self.favoris
        
        let encodedData = NSKeyedArchiver.archivedDataWithRootObject(AppValues.favorisItineraires)
        defaults.setObject(encodedData, forKey: "itinerairesFavoris")
        
        var listeItems: [UIBarButtonItem] = []
        
        var favoris = false
        
        for x in AppValues.favorisItineraires {
            if x[0].nomComplet == ItineraireEnCours.itineraire.depart?.nomComplet && x[1].nomComplet == ItineraireEnCours.itineraire.arrivee?.nomComplet {
                favoris = true
                break
            }
        }
        if favoris {
            listeItems.append(UIBarButtonItem(image: FAKFontAwesome.starIconWithSize(20).imageWithSize(CGSize(width: 20,height: 20)), style: UIBarButtonItemStyle.Done, target: self, action: #selector(ListeItinerairesTableViewController.toggleFavorite(_:))))
        }
        else {
            listeItems.append(UIBarButtonItem(image: FAKFontAwesome.starOIconWithSize(20).imageWithSize(CGSize(width: 20,height: 20)), style: UIBarButtonItemStyle.Done, target: self, action: #selector(ListeItinerairesTableViewController.toggleFavorite(_:))))
        }
        self.navigationItem.rightBarButtonItems = listeItems
        let navController = self.splitViewController?.viewControllers[0] as! UINavigationController
        if (navController.viewControllers[0].isKindOfClass(ItineraireTableViewController)) {
            let itineraireTableViewController = navController.viewControllers[0] as! ItineraireTableViewController
            itineraireTableViewController.tableView.reloadData()
        }
    }
    func scheduleNotification(time: NSDate, before: Int = 5, ligne: String, direction: String, arretDescente: String) {
        let time2 = time - before.minutes
        let now: NSDateComponents = NSCalendar.currentCalendar().components([.Hour, .Minute, .Second], fromDate: time2)
        
        let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        
        let date = cal.dateBySettingHour(now.hour, minute: now.minute, second: now.second, ofDate: time, options: NSCalendarOptions())
        let reminder = UILocalNotification()
        reminder.fireDate = date
        
        var texte =  "Le tpg de la ligne ".localized()
        texte += ligne
        texte += " en direction de ".localized()
        texte += direction
        if before == 0 {
            texte += " va partir immédiatement. ".localized()
        }
        else {
            texte += " va partir dans ".localized()
            texte += String(before)
            texte += " minutes. ".localized()
        }
        texte += "Descendez à ".localized()
        texte += String(arretDescente)
        
        reminder.alertBody = texte
        reminder.soundName = UILocalNotificationDefaultSoundName
        
        UIApplication.sharedApplication().scheduleLocalNotification(reminder)
        
        AppValues.logger.info("Firing at \(now.hour):\(now.minute - before):\(now.second)")
        
        let okView = SCLAlertView()
        if before == 0 {
            okView.showSuccess("Vous serez notifié".localized(), subTitle: "La notification à été enregistrée et sera affichée à l'heure du départ.".localized(), closeButtonTitle: "OK".localized(), duration: 10)
        }
        else {
            var texte = "La notification à été enregistrée et sera affichée ".localized()
            texte += String(before)
            texte += " minutes avant le départ.".localized()
            okView.showSuccess("Vous serez notifié".localized(), subTitle: texte, closeButtonTitle: "OK".localized(), duration: 10)
        }
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let time = NSDate(timeIntervalSince1970: Double(ItineraireEnCours.itineraireResultat[indexPath.row].timestampDepart)).timeIntervalSinceDate(NSDate())
        let timerAction = UITableViewRowAction(style: .Default, title: "Rappeler".localized()) { (action, indexPath) in
            let icone = FAKIonIcons.iosClockIconWithSize(20)
            icone.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
            icone.imageWithSize(CGSize(width: 20, height: 20))
            let alertView = SCLAlertView()
            if time < 60 {
                alertView.showWarning("Le bus arrive".localized(), subTitle: "Dépêchez vous, vous allez le rater !".localized(), closeButtonTitle: "OK".localized(), duration: 10)
            }
            else {
                alertView.addButton("A l'heure du départ".localized(), action: { () -> Void in
                    self.scheduleNotification(NSDate(timeIntervalSinceNow: time), before: 0, ligne: ItineraireEnCours.itineraireResultat[indexPath.row].correspondances[0].ligne, direction: ItineraireEnCours.itineraireResultat[indexPath.row].correspondances[0].direction, arretDescente:  ItineraireEnCours.itineraireResultat[indexPath.row].correspondances[0].a)
                    
                })
                if time > 60 * 5 {
                    alertView.addButton("5 min avant le départ".localized(), action: { () -> Void in
                        self.scheduleNotification(NSDate(timeIntervalSinceNow: time), before: 5, ligne: ItineraireEnCours.itineraireResultat[indexPath.row].correspondances[0].ligne, direction: ItineraireEnCours.itineraireResultat[indexPath.row].correspondances[0].direction, arretDescente:  ItineraireEnCours.itineraireResultat[indexPath.row].correspondances[0].a)
                    })
                }
                if time > 60 * 10 {
                    alertView.addButton("10 min avant le départ".localized(), action: { () -> Void in
                        self.scheduleNotification(NSDate(timeIntervalSinceNow: time), before: 10, ligne: ItineraireEnCours.itineraireResultat[indexPath.row].correspondances[0].ligne, direction: ItineraireEnCours.itineraireResultat[indexPath.row].correspondances[0].direction, arretDescente:  ItineraireEnCours.itineraireResultat[indexPath.row].correspondances[0].a)
                    })
                }
                alertView.addButton("Autre", action: { () -> Void in
                    alertView.hideView()
                    let customValueAlert = SCLAlertView()
                    let txt = customValueAlert.addTextField("Nombre de minutes".localized())
                    txt.keyboardType = .NumberPad
                    txt.becomeFirstResponder()
                    customValueAlert.addButton("Rappeler".localized(), action: { () -> Void in
                        if Int(time) < Int(txt.text!)! * 60 {
                            customValueAlert.hideView()
                            SCLAlertView().showError("Il y a un problème".localized(), subTitle: "Merci de taper un nombre inférieur à la durée restante avant l'arrivée du tpg.".localized(), closeButtonTitle: "OK", duration: 10)
                            
                        }
                        else {
                            self.scheduleNotification(NSDate(timeIntervalSinceNow: time), before: Int(txt.text!)!, ligne: ItineraireEnCours.itineraireResultat[indexPath.row].correspondances[0].ligne, direction: ItineraireEnCours.itineraireResultat[indexPath.row].correspondances[0].direction, arretDescente:  ItineraireEnCours.itineraireResultat[indexPath.row].correspondances[0].a)
                            customValueAlert.hideView()
                        }
                    })
                    customValueAlert.showNotice("Rappeler".localized(), subTitle: "Quand voulez-vous être notifié(e) ?".localized(), closeButtonTitle: "Annuler".localized(), circleIconImage: icone.imageWithSize(CGSize(width: 20, height: 20)))
                })
                alertView.showNotice("Rappeler".localized(), subTitle: "Quand voulez-vous être notifié(e) ?".localized(), closeButtonTitle: "Annuler".localized(), circleIconImage: icone.imageWithSize(CGSize(width: 20, height: 20)))
                tableView.setEditing(false, animated: true)
            }
            
        }
        timerAction.backgroundColor = UIColor.flatBlueColor()
        return [timerAction]
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if pasReseau || ItineraireEnCours.itineraireResultat.count == 0 {
            return false
        }
        else {
            return true
        }
    }
}
