//
//  ViewController.swift
//  Clocked
//
//  Created by Nix on 11/12/18.
//  Copyright © 2018 NXN. All rights reserved.
//

import UIKit
import CoreData
class TimeCardsViewController: UITableViewController {
    
    let cellId = "cellId"
    var timecards: [NSManagedObject] = []
    var total: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(TimeCardTableViewCell.self, forCellReuseIdentifier: cellId)
//        layoutSubviews()
        
        let backItem = UIBarButtonItem()
        backItem.title = "Cancel"
        navigationItem.backBarButtonItem = backItem
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action:#selector(addTimeCardButtonAction(_:)))
        
        tableView.rowHeight = 60
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "TimeCards")
        
        do {
            timecards = try managedContext.fetch(fetchRequest)
            timecards = timecards.reversed()
            tableView.reloadData()
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        print(timecards)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return timecards.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
            cell.textLabel?.text = "Total"
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as? TimeCardTableViewCell else {
            return UITableViewCell() }
        
        let startTime: Date? = timecards[indexPath.row].value(forKeyPath: "startTime") as? Date
        let endTime: Date? = timecards[indexPath.row].value(forKeyPath: "endTime") as? Date
        
        let timecard: TimeCard = TimeCard()
        timecard.startTime = startTime
        timecard.endTime = endTime
        
        cell.startDateLabel.text = "\(startTime?.dayOfWeek() ?? "") \(startTime?.dateAsString() ?? "")"
        cell.startTimeLabel.text = startTime?.timeAsString()
        cell.endTimeLabel.text = endTime?.timeAsString()
        cell.durationLabel.text = timecard.durationAsString

        return cell
    }
    
    @objc func addTimeCardButtonAction(_ sender: UIBarButtonItem) {
        navigationController?.pushViewController(TimeCardDetailsViewController(), animated: true)
    }

}

