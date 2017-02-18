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
import Firebase
import LNRSimpleNotifications
import AudioToolbox
import SwiftHEXColors

class ViewController: UIViewController {

  /// Bluetoothe manager
  private let manager = BluetoothManager(queue: .main)
  
  /// Dispose bag
  private let disposeBag = DisposeBag()
  
  /// Firebase database
  var ref:  FIRDatabaseReference!
  
  /// Weight label
  @IBOutlet var weight: UILabel!
  
  let notificationManager = LNRNotificationManager()

  override func viewDidLoad() {
    super.viewDidLoad()
    
    ref = FIRDatabase.database().reference()
    
    notificationManager.notificationsPosition = LNRNotificationPosition.top
    notificationManager.notificationsBackgroundColor = UIColor(hexString: "#A1BF35")!
    notificationManager.notificationsTitleTextColor = UIColor(hexString: "#575656")!
    notificationManager.notificationsBodyTextColor = UIColor.white //UIColor(hexString: "#A1BF35")!
    notificationManager.notificationsSeperatorColor = UIColor(hexString: "#575656")!// UIColor.white
    notificationManager.notificationsIcon = UIImage(named: "icon.png")
    
    let alertSoundURL: NSURL? = Bundle.main.url(forResource: "smoke-detector-1", withExtension: "wav") as NSURL?
    if let _ = alertSoundURL {
      var mySound: SystemSoundID = 0
      AudioServicesCreateSystemSoundID(alertSoundURL!, &mySound)
      notificationManager.notificationSound = mySound
    }
  }
  
  @IBAction func scan(_ sender: Any) {
  
    self.showNotification()
  
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
          // convert service
          .flatMap { $0.discoverServices([service]) }
          .flatMap { Observable.from($0) }
          
          // convert characteristic
          .flatMap { $0.discoverCharacteristics([characteristic])}
          .flatMap { Observable.from($0) }
          
          // read value
          .flatMap { $0.readValue() }
          .subscribe(onNext: {
          
            self.saveWeight(data: $0.value)
          
            // monitor updates
            $0.setNotificationAndMonitorUpdates().asObservable().subscribe(onNext: {
              self.saveWeight(data: $0.value)
            })
            .addDisposableTo(self.disposeBag)
            
          },
          onError: { error in
            print("--> error \(error)")
          })
          .disposed(by: self.disposeBag)
        
      }, onError: { print("error \($0)") })
      .addDisposableTo(disposeBag)
  }
  
  private func showNotification() {
    notificationManager.showNotification(notification: LNRNotification(title: "OwlBowl", body: "Please order some new fruits mate!", duration: -1, onTap: { () -> Void in
      print("Notification Dismissed")
    }, onTimeout: { () -> Void in
      print("Notification Timed Out")
    }))
  }
  
  /**
    Save weight to Firebase
  */
  private func saveWeight(data: Data?) {
    guard let value = data?.hashValue else {
      return
    }
    
    self.weight.text = "\(value)"
    
    print("Weight = \(value)")

    self.ref.child("scale").child("weight").setValue(value)
  }
}
