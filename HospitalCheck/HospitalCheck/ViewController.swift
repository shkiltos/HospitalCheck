//
//  ViewController.swift
//  HospitalCheck
//
//  Created by Anton Shkilevich on 18/12/2020.
//  Copyright © 2020 Anton Shkilevich. All rights reserved.
//

import UIKit
import CocoaMQTT

class ViewController: UIViewController {

    @IBOutlet weak var mqttLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {        navigationController?.navigationBar.isHidden = false
    }
    
    func updateStatusLabel(status: String) {
        statusLabel.text = status
    }
}

