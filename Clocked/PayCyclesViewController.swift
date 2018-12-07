//
//  PayCycleViewController.swift
//  Clocked
//
//  Created by Nix on 12/4/18.
//  Copyright © 2018 NXN. All rights reserved.
//

import UIKit
import CoreData

class PayCyclesViewController: UITableViewController {
    // what does this cellId mean?
    let cellId = "cellId"
    var payCycles: [PayCycles] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        
        navigationItem.title = "Pay Cycles"
        
        let backItem = UIBarButtonItem()
        backItem.title = "Pay Cycles"
        navigationItem.backBarButtonItem = backItem
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addPayCycleButtonAction(_:)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<PayCycles>(entityName: "PayCycles")
        
        do {
            payCycles = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payCycles.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        
        cell.textLabel?.text = "Start: End:"
        return cell 
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let timeCardViewController = TimeCardsViewController(payCycle: payCycles[indexPath.row])
        
        navigationController?.pushViewController(timeCardViewController, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            
            let managedContext =
                appDelegate.persistentContainer.viewContext
            
            let payCycleObject: PayCycles = payCycles[indexPath.row]
            
            payCycles.remove(at: indexPath.row)
            managedContext.delete(payCycleObject)
            do {
                try managedContext.save()
                tableView.deleteRows(at: [IndexPath(row: indexPath.row, section: indexPath.section)], with: UITableView.RowAnimation.automatic)
            } catch let error as NSError {
                print("Could not delete. \(error), \(error.userInfo)")
            }
        }
    }
    
    @objc func addPayCycleButtonAction(_ sender: UIBarButtonItem) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext

        let _: PayCycles = PayCycles(context: managedContext)
        
        do {
            try managedContext.save()
            tableView.reloadData()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
}

