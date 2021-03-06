//
//  TimeCardDetailsViewController.swift
//  Clocked
//
//  Created by Nix on 11/14/18.
//  Copyright © 2018 NXN. All rights reserved.
//

import UIKit
import CoreData
import Foundation

class TimeCardDetailsViewController: UITableViewController, DatePickerDelegate, CloseDatePickerDelegate {
    let managedContext: NSManagedObjectContext
    let payCycle: ManagedPayCycle
    var timeCard: ManagedTimeCard
    let newTimeCard: Bool
    var datePickerIndexPath: IndexPath?
    let timeCardDetails: TimeCardDetailsModel
    var items: [TimeCardDetailsItem]
    
    init (payCycle: ManagedPayCycle, prevTimeCard: ManagedTimeCard?, managedContext: NSManagedObjectContext) {
        self.managedContext = managedContext
        self.payCycle = payCycle
        self.timeCard = prevTimeCard ?? ManagedTimeCard(context: managedContext)
        self.newTimeCard = (prevTimeCard == nil)
        self.timeCardDetails = TimeCardDetailsModel(timeCard: self.timeCard, managedContext: managedContext)
        self.items = self.timeCardDetails.items
        
        super.init(style: .plain)
        
        if newTimeCard {
            guard let timeStampsItem = items[0] as? TimeCardDetailsTimeStampsItem else {
                return
            }
            var timeStamps = timeStampsItem.timeStamps
            let currentTime = Date().roundToNearestFiveMin()
            timeStamps[0] = currentTime
            timeStampsItem.save(new: timeStamps)
            timeCard.startTime = currentTime
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationItem()
        setupToolbar()
    }
    
    func setupTableView() {
        tableView.register(LRLabelTableViewCell.self, forCellReuseIdentifier: LRLabelTableViewCell.resuseIdentifier())
        tableView.register(DatePickerTableViewCell.self, forCellReuseIdentifier: DatePickerTableViewCell.reuseIdentifier())
        tableView.register(PurchaseTableViewCell.self, forCellReuseIdentifier: PurchaseTableViewCell.reuseIdentifier())
        tableView.register(HeaderFooterView.self, forHeaderFooterViewReuseIdentifier: HeaderFooterView.reuseIdentifier())
        
        let footerView = { () -> HeaderFooterView in
            guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: HeaderFooterView.reuseIdentifier()) as? HeaderFooterView else {
                return HeaderFooterView()
            }
            return view
        }()
        tableView.backgroundColor = #colorLiteral(red: 0.9418308139, green: 0.9425446987, blue: 0.9419413209, alpha: 1)
        tableView.tableFooterView = footerView
        
        tableView.estimatedRowHeight = 45
        tableView.rowHeight = 45
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        
        //tap does not interfere and cancel other interactions.
        tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
    }
    
    func setupNavigationItem() {
        if newTimeCard {
            navigationController?.title = "New Entry"
        } else {
            navigationController?.title = "Edit Entry"
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonAction(_:)))
        
        let backItem = UIBarButtonItem(barButtonSystemItem: .camera, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
    }
    
    func setupToolbar() {
        navigationController?.setToolbarHidden(false, animated: true)
        var items:[UIBarButtonItem] = []
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let addPurchaseButton = UIBarButtonItem(title: "Add Purchase", style: .plain, target: self, action: #selector(addPurchaseButtonAction))
        
        items.append(space)
        items.append(addPurchaseButton)
        self.setToolbarItems(items, animated: true)
    }
    
    @objc func addPurchaseButtonAction() {
        closeDatePicker()
        guard let purchaseItem = items[2] as? TimeCardDetailsPurchaseItem else {
            return
        }
        
        purchaseItem.addToManagedPurchases(newPurchase: ManagedPurchase(context: managedContext))
        tableView.insertRows(at: [IndexPath(row: purchaseItem.rowCount - 1, section: 2)], with: .top)
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: HeaderFooterView.reuseIdentifier()) as? HeaderFooterView else {
            return HeaderFooterView()
        }
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 1 {
            return UITableView.automaticDimension
        } else {
            return CGFloat.leastNormalMagnitude
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if items[section].type == .timeStamps && datePickerIndexPath != nil {
            return items[section].rowCount + 1
        } else {
            return items[section].rowCount
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if datePickerIndexPath == indexPath {
            let datePickerCell = setupDatePickerCell(indexPath: indexPath)
            
            return datePickerCell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: LRLabelTableViewCell.resuseIdentifier()) as? LRLabelTableViewCell else {
                return LRLabelTableViewCell()
            }
            
            switch items[indexPath.section].type {
            case .timeStamps:
                let timeStampsItem = items[indexPath.section] as! TimeCardDetailsTimeStampsItem
                let timeStamps = timeStampsItem.timeStamps
                let row = indexPath.row <= 1 ? indexPath.row : 1
                let timestamp = timeStamps[row]
                
                if row == 0 {
                    cell.leftLabel.text = "Starts"
                } else if row == 1 {
                    cell.leftLabel.text = "Ends"
                }
                
                cell.rightLabel.text = {
                    guard let timestamp = timestamp else {
                        return ""
                    }
                                        
                    return "\(timestamp.dateAsString())    \(timestamp.timeAsString())"
                }()
                
                return cell
            case .duration:
                let durationItem = items[indexPath.section] as! TimeCardDetailsDurationItem
                
                cell.leftLabel.text = "Duration"
                cell.rightLabel.text = durationItem.duration
                
                return cell
            case .purchases:
                let purchaseItem = items[indexPath.section] as! TimeCardDetailsPurchaseItem
                let managedPurchases = purchaseItem.managedPurchases
                
                return setupPurchaseCell(managedPurchase: managedPurchases[indexPath.row])
            }
        }
    }
    
    func setupDatePickerCell(indexPath: IndexPath) -> UITableViewCell {
        guard let datePickerCell = tableView.dequeueReusableCell(withIdentifier: DatePickerTableViewCell.reuseIdentifier()) as? DatePickerTableViewCell else {
            return DatePickerTableViewCell() }
        
        let timeStampsItem = items[indexPath.section] as! TimeCardDetailsTimeStampsItem
        let timeStamps = timeStampsItem.timeStamps
        datePickerCell.updateCell(date: timeStamps[indexPath.row - 1], indexPath: indexPath)
        datePickerCell.delegate = self
        
        return datePickerCell
    }
    
    func setupPurchaseCell(managedPurchase: ManagedPurchase) -> UITableViewCell {
        guard let purchaseCell = tableView.dequeueReusableCell(withIdentifier: PurchaseTableViewCell.reuseIdentifier()) as? PurchaseTableViewCell else {
            return PurchaseTableViewCell()
        }
        purchaseCell.itemNameTextField.text = managedPurchase.name
        purchaseCell.itemNameTextField.closeDatePickerDelegate = self
        purchaseCell.priceTextField.updatePriceTextField(price: managedPurchase.price)
        purchaseCell.priceTextField.closeDatePickerDelegate = self
        
        return purchaseCell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath == datePickerIndexPath {
            return DatePickerTableViewCell.height
        } else {
            return tableView.rowHeight
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let item = items[indexPath.section]
        
        if item.type == .purchases {
            return true
        } else {
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            tableView.beginUpdates()
            let purchaseItem = items[indexPath.section] as! TimeCardDetailsPurchaseItem
            
            managedContext.delete(purchaseItem.managedPurchases[indexPath.row])
            purchaseItem.removeFromManagedPurchases(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            tableView.endUpdates()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.beginUpdates()
        
        // close open date picker
        if let datePickerIndexPath = datePickerIndexPath, datePickerIndexPath.row - 1 == indexPath.row {
            tableView.deleteRows(at: [datePickerIndexPath], with: .fade)
            self.datePickerIndexPath = nil
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            switch items[indexPath.section].type {
            case .timeStamps:
                guard let timeStampsItem = items[indexPath.section] as? TimeCardDetailsTimeStampsItem else {
                    return
                }
                var timeStamps = timeStampsItem.timeStamps
                let datePickerIsOpen: Bool = (datePickerIndexPath != nil)
                var prevDatePickerIndex: IndexPath?
                
                if datePickerIsOpen {
                    prevDatePickerIndex = datePickerIndexPath
                }
                
                datePickerIndexPath = indexPathToInsertDatePicker(indexPath: indexPath)
                guard let datePickerIndexPath = datePickerIndexPath else {
                    return
                }
                
                if timeStamps[datePickerIndexPath.row - 1] == nil {
                    timeStamps[datePickerIndexPath.row - 1] = Date(timeInterval: TimeInterval(exactly: 3600)!, since: timeStamps[0]!)
                    timeStampsItem.save(new: timeStamps)
                    updateDuration()
                }

                if datePickerIsOpen {
                    if let prevDatePickerIndex = prevDatePickerIndex{
                        tableView.deleteRows(at: [prevDatePickerIndex], with: .fade)
                        tableView.insertRows(at: [datePickerIndexPath], with: .fade)
                        
                        tableView.endUpdates()
                        tableView.beginUpdates()
                        tableView.reloadRows(at: [IndexPath(row: datePickerIndexPath.row - 1, section: datePickerIndexPath.section)], with: .none)
                    }
                } else {
                    tableView.insertRows(at: [datePickerIndexPath], with: .fade)
                    tableView.deselectRow(at: indexPath, animated: true)
                    tableView.reloadRows(at: [IndexPath(row: datePickerIndexPath.row - 1, section: datePickerIndexPath.section)], with: .none)
                }

            default:
                closeDatePicker()
                tableView.deselectRow(at: indexPath, animated: false)
            }
        }
        tableView.endUpdates()
    }
    
    func indexPathToInsertDatePicker(indexPath: IndexPath) -> IndexPath {
        if let datePickerIndexPath = datePickerIndexPath, datePickerIndexPath.row < indexPath.row {
            return indexPath
        } else {
            return IndexPath(row: indexPath.row + 1, section: indexPath.section)
        }
    }
    
    func didChangeDate(date: Date, indexPath: IndexPath) {
        guard let datePickerIndexPath = datePickerIndexPath else {
            return
        }
        let section = datePickerIndexPath.section
        let row = datePickerIndexPath.row - 1
        let timeStampsItem = items[section] as! TimeCardDetailsTimeStampsItem
        var timeStamps = timeStampsItem.timeStamps

        timeStamps[row] = date
        timeStampsItem.save(new: timeStamps)
        
        tableView.reloadRows(at: [IndexPath(row: row, section: section)], with: .none)
        updateDuration()
    }
    
    func closeDatePicker() {
        tableView.beginUpdates()
        
        if let datePickerIndexPath = datePickerIndexPath {
            tableView.deleteRows(at: [datePickerIndexPath], with: .fade)
            self.datePickerIndexPath = nil
        }
        
        tableView.endUpdates()
    }
    
    func updateDuration() {
        guard let datePickerIndexPath = datePickerIndexPath else {
            return
        }
        let section = datePickerIndexPath.section
        guard let timeStampsItem = items[section] as? TimeCardDetailsTimeStampsItem else {
            return
        }
        let timeStamps = timeStampsItem.timeStamps
        
        guard let start = timeStamps[0], let end = timeStamps[1] else {
            return
        }
        
        let durationItem = items[1] as! TimeCardDetailsDurationItem
        
        durationItem.duration = hoursAndMins(from: start, to: end)
        tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
    }
    
    enum TimeCardError: Error {
        case noTimeStampItem
        case invalidTimes
        case noStartTime
        case purchaseWithNoName
        case unknown
    }
    
    @objc func saveButtonAction(_ sender: UIBarButtonItem) {
        do {
            try saveTimeStamps()
        } catch TimeCardError.noTimeStampItem {
            return
        } catch TimeCardError.invalidTimes {
            presentAlert(for: .invalidTimes)
        } catch TimeCardError.noStartTime {
            presentAlert(for: .noStartTime)
        } catch {
            presentAlert(for: .unknown)
        }

        do {
            try savePurchases()
        } catch TimeCardError.purchaseWithNoName {
            presentAlert(for: .purchaseWithNoName)
        } catch {
            presentAlert(for: .unknown)
        }
            
        do {
            try managedContext.save()
            navigationController?.popViewController(animated: true)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    func saveTimeStamps() throws {
        guard let timeStampsItem = items[0] as? TimeCardDetailsTimeStampsItem else {
            throw TimeCardError.noTimeStampItem
        }
        
        let timeStamps = timeStampsItem.timeStamps
        
        guard let start = timeStamps[0] else {
            throw TimeCardError.noStartTime
        }
        
        if let end = timeStamps[1] {
            guard duration(from: start, to: end) >= 0 else {
                throw TimeCardError.invalidTimes
            }
        }
        
        timeCard.startTime = timeStamps[0]
        timeCard.endTime = timeStamps[1]

        if newTimeCard {
            guard let payCycleWithChildContext = managedContext.object(with: payCycle.objectID) as? ManagedPayCycle else {
                return
            }
            payCycleWithChildContext.addToTimeCards(timeCard)
        }
    }
    
    func savePurchases() throws {
        guard let purchaseItem = items[2] as? TimeCardDetailsPurchaseItem else {
            return
        }
        guard let timeCardWithChildContext = managedContext.object(with: timeCard.objectID) as? ManagedTimeCard else {
            return
        }
        let managedPurchases = purchaseItem.managedPurchases
        
        let cells = self.tableView.visibleCells
        let purchaseTableViewCells = cells.filter {
            $0 is PurchaseTableViewCell  }
        for idx in 0..<purchaseTableViewCells.count {
            guard let cell = purchaseTableViewCells[idx] as? PurchaseTableViewCell else {
                return
            }
            let managedPurchase = managedPurchases[idx]
            
            // do not add empty entries to timecard
            if let itemName = cell.itemNameTextField.text, itemName.count > 0 {
                managedPurchase.name = cell.itemNameTextField.text
                managedPurchase.price = currencyToFloat(from: cell.priceTextField.amountTypedString)
                if idx >= purchaseItem.indexOfMostRecentPurchase {
                    timeCardWithChildContext.addToPurchases(managedPurchase)
                }
            } else if cell.priceTextField.amountTypedString.count > 0 {
                throw TimeCardError.purchaseWithNoName
            } else {
                managedContext.delete(managedPurchases[idx])
            }
        }
    }
    
    func presentAlert(for errorType: TimeCardError) {
        let title: String = "Cannot Save Entry"
        var message: String
        
        switch errorType {
        case .noStartTime:
            message = "An entry must have a start time"
        case .invalidTimes:
            message = "The start time must be before the end time"
        case .purchaseWithNoName:
            message = "A purchase must have a name"
        default:
            message = "Unknown Error"
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

