//
//  PurchaseTableViewCell.swift
//  Clocked
//
//  Created by Nix on 12/28/18.
//  Copyright © 2018 NXN. All rights reserved.
//

import Foundation
import UIKit

enum PurchaseTextFieldOptions {
    case name
    case price
}

class PurchaseTableViewCell: UITableViewCell {
    let itemNameTextField: PurchaseTextField
    let priceTextField: PriceTextField
    
    static func reuseIdentifier() -> String {
        return "PurchaseTableViewCellIdentifier"
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.itemNameTextField = PurchaseTextField(option: .name)
        self.priceTextField = PriceTextField()
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        addSubview(itemNameTextField)
        addSubview(priceTextField)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let textFields = [itemNameTextField, priceTextField]
        
        for textField in textFields {
            textField.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let padding: CGFloat = 16
        
        NSLayoutConstraint.activate([
            itemNameTextField.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: padding),
            itemNameTextField.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor, multiplier: 0.70),
            itemNameTextField.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            itemNameTextField.heightAnchor.constraint(equalTo: safeAreaLayoutGuide.heightAnchor),
            
            priceTextField.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -padding),
            priceTextField.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor, multiplier: 0.20),
            priceTextField.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            priceTextField.heightAnchor.constraint(equalTo: safeAreaLayoutGuide.heightAnchor),
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        itemNameTextField.text = ""
        priceTextField.text = ""
        priceTextField.amountTypedString = ""
    }
}

class PurchaseTextField: UITextField, UITextFieldDelegate {
    var closeDatePickerDelegate: CloseDatePickerDelegate?
    
    init(frame: CGRect = CGRect.zero, option: PurchaseTextFieldOptions) {
        super.init(frame: frame)
        
        switch option {
        case .name:
            self.placeholder = "Item Name"
            self.keyboardType = UIKeyboardType.default
            self.clearButtonMode = UITextField.ViewMode.whileEditing
        case .price:
            self.placeholder = "$0.00"
            self.keyboardType = UIKeyboardType.numberPad
        }
        
        self.autocorrectionType = UITextAutocorrectionType.default
        self.returnKeyType = UIReturnKeyType.done
        self.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        self.delegate = self
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        closeDatePickerDelegate?.closeDatePicker()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

protocol CloseDatePickerDelegate {
    func closeDatePicker()
}

class PriceTextField: PurchaseTextField {
    var amountTypedString: String = ""
    init() {
        super.init(frame: .zero, option: .price)
        
        self.textAlignment = .right
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.count > 0 {
            amountTypedString = amountTypedString + string
            let amount = stringToCurrency(from: amountTypedString)
            textField.text = amount
        } else {
            amountTypedString = String(amountTypedString.dropLast())
            if amountTypedString.count > 0 {
                let amount = stringToCurrency(from: amountTypedString)
                textField.text = amount
            } else {
                textField.text = ""
            }
        }
        return false
    }
}

extension PriceTextField {
    func updatePriceTextField(price: Float) {
        if price <= 0.0 {
            return
        } else {
            let amountString = priceToString(from: price)
            let amountCurrency = stringToCurrency(from: amountString)
            
            self.amountTypedString = amountString
            self.text = amountCurrency
        }
    }
}
