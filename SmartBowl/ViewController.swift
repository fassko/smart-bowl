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
import MMWormhole


class ViewController: UIViewController {

  /// Bluetoothe manager
  private let manager = BluetoothManager(queue: .main)
  
  /// Dispose bag
  private let disposeBag = DisposeBag()
  
  /// Firebase database
  var ref:  FIRDatabaseReference!
  
  /// Lottie animation view
//  fileprivate var lottieLogo: LOTAnimationView!
  
  /// Notification manager
  let notificationManager = LNRNotificationManager()
  
  var changes: Variable<Int> = Variable(0)
  
  var timeMeasured: Date?
  
  /// Weight label
  @IBOutlet var weight: UILabel!
  
  @IBOutlet var connectButton: UIButton!
  
  @IBOutlet var bowl: UIImageView!
  
  var wormhole:MMWormhole?
  
  @IBAction func changes(_ sender: Any) {
    changes.value += 1
  }
  
  @IBAction func reset(_ sender: Any) {
    changes.value = 0
  }
  
  var i = 0
  
  @IBAction func post(_ sender: Any) {
    
    i += 1
    
    wormhole?.passMessageObject("\(i) grams" as NSCoding?, identifier: "scale")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
//    wormhole = MMWormhole(applicationGroupIdentifier: "group.owlbowl.scale", optionalDirectory: nil)
//    wormhole?.listenForMessage(withIdentifier: "scale", listener: { (message ) -> Void in
//      if let messageFromWatch = message as? String {
//            // do something with messageFromWatch
//      }
//    })
    
    changes.asObservable()
      .flatMap({c -> Observable<Int> in
        
        if c >= 4 {
          return Observable.just(4)
        }
        
        return Observable.just(c)
      })
      .subscribe(onNext: {c in
      
      
        if c == 3 {
          self.showNotification()
        }
      
        print(c)
      
        let toImage = UIImage(named:"bowl\(c).png")
        
        UIView.transition(with: self.bowl,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                         animations: {
                             self.bowl.image = toImage
                         },
                         completion: nil)
      })
      .addDisposableTo(disposeBag)
    
//    lottieLogo = LOTAnimationView.animationNamed("LottieLogo1")
//    lottieLogo.contentMode = .scaleAspectFill
    
    connectButton.layer.borderWidth = 1
    connectButton.layer.borderColor = UIColor.white.cgColor
    
    ref = FIRDatabase.database().reference()
    
    notificationManager.notificationsPosition = LNRNotificationPosition.top
    notificationManager.notificationsBackgroundColor = UIColor(hexString: "#A1BF35")!
    notificationManager.notificationsTitleTextColor = UIColor(hexString: "#575656")!
    notificationManager.notificationsBodyTextColor = UIColor.white //UIColor(hexString: "#A1BF35")!
    notificationManager.notificationsSeperatorColor = UIColor(hexString: "#575656")!// UIColor.white
    notificationManager.notificationsIcon = UIImage(named: "icon.png")
    
//    let alertSoundURL: NSURL? = Bundle.main.url(forResource: "smoke-detector-1", withExtension: "wav") as NSURL?
//    if let _ = alertSoundURL {
//      var mySound: SystemSoundID = 0
//      AudioServicesCreateSystemSoundID(alertSoundURL!, &mySound)
//      notificationManager.notificationSound = mySound
//    }
  }
  
//  override func viewDidAppear(_ animated: Bool) {
//    lottieLogo.play()
//  }
//  
//  override func viewDidLayoutSubviews() {
//    lottieLogo.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height * 0.3)
//    view.addSubview(lottieLogo)
//  }
  
  @IBAction func scan(_ sender: Any) {
  
    let service = CBUUID(string: "180F")
    let characteristic = CBUUID(string: "2A19")
    
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
  
  /**
    Show notification
  */
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
    guard var value = data?.hashValue else {
      return
    }
    
//    let val = data?.withUnsafeBytes { (ptr: UnsafePointer<Double>) -> Double in
//      return ptr.pointee
//    }
//    print(val) // 42.13
//    print(Int(val!))
    
    let firstByte = data?[0]
    let secondByte = data?[1]
    
    print("\(firstByte) \(secondByte)")
    
    let weight = (Int(firstByte!) * 256) + Int(secondByte!)
    
    value = Int(weight)
    
    //    let data4 = data?.subdata(in: 0..<4)
    //    let int = CFSwapInt32BigToHost(data4)
        
    //    data4
    //    
    //    var i = CFSwapInt32BigToHost(data4
    //    
    //int value = CFSwapInt32BigToHost(*(int*)([data4 bytes]));

    //    let val = UInt32(bigEndian: bigEndianValue)

    self.weight.text = "\(value) grams"
    
    print("Weight = \(value)")

    
    if timeMeasured == nil || (timeMeasured != nil && Date().timeIntervalSince(timeMeasured!) > 3)  {
      // set value in Firebase
      self.ref.child("scale").child("weight").setValue(value)
      
      self.changes.value += 1
      
      timeMeasured = Date()
      
      
//      wormhole?.passMessageObject("\(value) grams" as NSCoding?, identifier: "scale")
      
    }

    
  }
}
