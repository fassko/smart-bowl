//
//  InterfaceController.swift
//  SmartBowl WatchKit Extension
//
//  Created by Kristaps Grinbergs on 18/02/2017.
//  Copyright © 2017 fassko. All rights reserved.
//

import WatchKit
import Foundation
import MMWormhole


class InterfaceController: WKInterfaceController {

  
  @IBOutlet var bowlImage: WKInterfaceImage!
  
  
  var i = 0
  
  @IBAction func change() {
  
    i += 1
  
    if i == 5 {
      i = 0
    }
    
    bowlImage.setImageNamed("bowl\(i).png")
  
  }
  

    override func awake(withContext context: Any?) {
      super.awake(withContext: context)
      
      
      
      
//      let wormhole = MMWormhole(applicationGroupIdentifier: "group.owlbowl.scale", optionalDirectory: nil)
//      wormhole.listenForMessage(withIdentifier: "scale", listener: { (message ) -> Void in
//      if let messageFromPhone = message as? String {
//        print(message)
//        self.scale.setText("\(message) grams")
//      }
//})
      
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
