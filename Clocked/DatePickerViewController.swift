//
//  DatePickerViewController.swift
//  Clocked
//
//  Created by Nix on 11/15/18.
//  Copyright © 2018 NXN. All rights reserved.
//

import UIKit

class DatePickerViewController: UIViewController {
    var delegate: DatePickerDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveDateTime(_:)))
        
        let datePickerContainer = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))

        datePickerContainer.backgroundColor = .white
        let datePicker: UIDatePicker = UIDatePicker()
        
        datePicker.timeZone = NSTimeZone.local

        datePickerContainer.addSubview(datePicker)
        
        view.addSubview(datePickerContainer)
    }
    
    @objc func saveDateTime(_ sender: UIBarButtonItem) {
        delegate?.DateTimeSelected(value: "11/25/2018 12:00:00")
        navigationController?.popViewController(animated: true)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
