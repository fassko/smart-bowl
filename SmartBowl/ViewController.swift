//
//  ViewController.swift
//  SmartBowl
//
//  Created by Kristaps Grinbergs on 18/02/2017.
//  Copyright © 2017 fassko. All rights reserved.
//

import UIKit

import RxBluetoothKit
import RxSwift
import CoreBluetooth

class ViewController: UIViewController {

  /// Bluetoothe manager
  private let manager = BluetoothManager(queue: .main)
  
  private let disposeBag = DisposeBag()
  
  /// Weigh
  @IBOutlet var weight: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  @IBAction func scan(_ sender: Any) {
  
    let service = CBUUID(string: "180F")
    let characteristic = CBUUID(string: "2A19")
    
    // 255 - sleep
    // 0 - garbage
    // > 30 == 0
    
    
    manager.scanForPeripherals(withServices: [service])
      .filter({ peripheral in

        guard let localName = peripheral.advertisementData.advertisementData["kCBAdvDataLocalName"] as? String else {
          return false
        }
        
        return localName == "FruitsOrder"
       
      })
      .subscribe(onNext: {peripheral in
      
        peripheral.peripheral.connect()
          .flatMap { $0.discoverServices([service]) }
          .flatMap { Observable.from($0) }
          .flatMap { $0.discoverCharacteristics([characteristic])}
          .flatMap { Observable.from($0) }
          .flatMap { $0.readValue() }
          .subscribe(onNext: {
            print("Value = $0.value?.hashValue")
            
            guard let value = $0.value?.hashValue else {
              return
            }
              
            self.weight.text = "\(value)"
          
            $0.setNotificationAndMonitorUpdates().asObservable().subscribe(onNext: {
              print("New value \($0.value?.hashValue)")
              
              guard let value = $0.value?.hashValue else {
                return
              }
              
              self.weight.text = "\(value)"
            })
          },
          onError: { error in
            print("--> error \(error)")
          })
          .disposed(by: self.disposeBag)
        
      }, onError: { print("error \($0)") })
      .addDisposableTo(disposeBag)
  }
}

