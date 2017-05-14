//
//  TablePickerViewController.swift
//  Linus
//
//  Created by Nina Yang on 5/14/17.
//  Copyright © 2017 Nina Yang. All rights reserved.
//

import UIKit

class TablePickerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet fileprivate weak var tablePicker: UIPickerView!
    
    fileprivate var pickerData: [String] = ["A1", "A2", "A3", "A4", "B1", "B2", "B3", "B4", "C1", "C2", "C3", "C4"]
    fileprivate var table: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.tablePicker.delegate = self
        self.tablePicker.dataSource = self
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let titleData = pickerData[row]
        self.table = titleData
        let myTitle = NSAttributedString(string: titleData, attributes: [NSFontAttributeName:UIFont(name: "MyriadPro-Regular", size: 18.0)!,NSForegroundColorAttributeName:UIColor.black])
        return myTitle
    }
    
    @IBAction func confirmTableTapped(_ sender: Any) {
        guard let table = table else { return }
        let orderVC = OrderViewController(withTable: table)
        self.navigationController?.pushViewController(orderVC, animated: true)
        
    }
    
    class func instanceFromNib() -> TablePickerViewController {
        return UINib(nibName: "TablePickerViewController", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! TablePickerViewController
    }
}

