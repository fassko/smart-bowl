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

  private let manager = BluetoothManager(queue: .main)
  
  private let disposeBag = DisposeBag()
  
  private var connectedPeripheral: Peripheral?
  
  @IBOutlet var weight: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  @IBAction func scan(_ sender: Any) {
  
  let service = CBUUID(string: "180F")
  let characteristic = CBUUID(string: "2A19")
    
//    CBUUID(string: "Battery")
//    CBUUID.
    
    manager.scanForPeripherals(withServices: [service])
      .filter({ peripheral in

        guard let localName = peripheral.advertisementData.advertisementData["kCBAdvDataLocalName"] as? String else {
          return false
        }
        
        return localName == "FruitsOrder"
       
      })
    
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
              print($0.value)
            
              guard var value = $0.value?.hashValue else {
                  return
                }
                
                self.weight.text = "\(value)"
            
            
            
              $0.setNotificationAndMonitorUpdates().asObservable().subscribe(onNext: {
                let newValue = $0.value
                print(newValue?.hashValue)
                
                guard var value = newValue?.hashValue else {
                  return
                }
                
                self.weight.text = "\(value)"
              })
          },
          onError: { error in print("--> error \(error)") })
          .disposed(by: self.disposeBag)

//        peripheral.peripheral.connect()
//          .flatMap({ $0.discoverServices([ service ]) })
//          .flatMap { Observable.from($0) }
////          .flatMap({ $0. })
//          .subscribe(onNext: {service in
//            print(service)
//          }).disposed(by: self.disposeBag)
        
        
        
      }, onError: { print("error \($0)") })
      .addDisposableTo(disposeBag)
    
//    manager.rx_state
//      .timeout(4.0, scheduler: MainScheduler.instance)
//      .take(1)
//      .flatMap { _ in self.manager.scanForPeripherals(withServices: nil, options:nil) }
//      .subscribeOn(MainScheduler.instance)
//      .subscribe(onNext: {peripheral in
//
//        guard let localName = peripheral.advertisementData.advertisementData["kCBAdvDataLocalName"] as? String else {
//          return
//        }
//        
//        if localName == "FruitsOrder" {
////          self.connect(peripheral: peripheral.peripheral)
//          
//          
//          //180F
//          
////          CBUUID
//          
//          
//          
//          self.manager.connect(peripheral.peripheral)
////            .flatMap({ $0.discoverServices(<#T##serviceUUIDs: [CBUUID]?##[CBUUID]?#>) })
//          
//            .subscribe(onNext: {p in
//              print("connected")
//              self.connectedPeripheral = p
//              
//              p.discoverServices(nil).subscribe(onNext: {s in
//                print(s)
//              }).addDisposableTo(self.disposeBag)
//              
//            }, onError: {error in
//              print("Can't connect \(error)")} )
//            .addDisposableTo(self.disposeBag)
//          
//        }
//      
//      }).addDisposableTo(disposeBag)
  }
  
  private func connect(peripheral: Peripheral) {
    manager.connect(peripheral)
      .subscribe(onNext: {p in
      
        self.connectedPeripheral = p
        
//          self.monitorDisconnection(for: $0)
//          self.downloadServices(for: $0)
      }).addDisposableTo(disposeBag)
  }
  
}

