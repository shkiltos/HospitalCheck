//
//  AppDelegate.swift
//  HospitalCheck
//
//  Created by Anton Shkilevich on 18/12/2020.
//  Copyright © 2020 Anton Shkilevich. All rights reserved.
//

import UIKit
import CocoaMQTT
import BackgroundTasks
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    
    let defaultHost = "127.0.0.1"
    var backgroundMessageReceived = false
    var mqtt: CocoaMQTT?
    let notificationCenter = UNUserNotificationCenter.current()
    let operationQueue = OperationQueue()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
        }
        notificationCenter.delegate = self
        
        setUpMQTT()
        
        registerBackgroundTasks()
        
        return true
    }
    
    func setUpMQTT() {
        RKMQTTConnectionManager.setup()
        RKMQTTConnectionManager.setDelegate(delegate: self)
    }

    func shouldSendNotification(msg: String) -> Bool {
        return true
    }
    
    func scheduleNotification(msg: String) {
        let content = UNMutableNotificationContent() // Содержимое уведомления
        
        content.title = "Alert"
        content.body = msg
        content.sound = UNNotificationSound.default
        content.badge = 0
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let identifier = "Local Notification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func registerBackgroundTasks() {
     // Declared at the "Permitted background task scheduler identifiers" in info.plist
     let backgroundAppRefreshTaskSchedulerIdentifier = "com.example.hospitalCheckRefreshIdentifier"
     let backgroundProcessingTaskSchedulerIdentifier = "com.example.hospitalProcessingRefreshIdentifier"

     BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundAppRefreshTaskSchedulerIdentifier, using: nil) { task in
          self.handleAppRefresh(task: task as! BGAppRefreshTask)
     }
    }
    
    func scheduleAppRefresh() {
       let request = BGAppRefreshTaskRequest(identifier: "com.example.apple-samplecode.ColorFeed.refresh")
       // Fetch no earlier than 15 minutes from now
       request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
            
       do {
          try BGTaskScheduler.shared.submit(request)
       } catch {
          print("Could not schedule app refresh: \(error)")
       }
    }
    
    
    // Not working part below. Needs to work when in background mode, but throws error
    func handleAppRefresh(task: BGAppRefreshTask) {
      // Schedule a new refresh task
      scheduleAppRefresh()

      // Create an operation that performs the main part of the background task
      let operation = BlockOperation {
        print("fetching")
        self.backgroundMessageReceived = false
        RKMQTTConnectionManager.createConnectionIfNecessary()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4), execute: {
            print("finished")
            if self.backgroundMessageReceived {
                print("Completed with data received")
            } else {
                print("No data")
            }
        })
      }
      
      // Provide an expiration handler for the background task
      // that cancels the operation
      task.expirationHandler = {
         operation.cancel()
      }

      // Inform the system that the background task is complete
      // when the operation completes
      operation.completionBlock = {
         task.setTaskCompleted(success: !operation.isCancelled)
      }

      // Start the operation
      operationQueue.addOperation(operation)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        RKMQTTConnectionManager.setDelegate(delegate: self)
    }
}

extension AppDelegate: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
    }
    
    
    // Optional ssl CocoaMQTTDelegate
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        TRACE("trust: \(trust)")
        /// Validate the server certificate
        ///
        /// Some custom validation...
        ///
        /// if validatePassed {
        ///     completionHandler(true)
        /// } else {
        ///     completionHandler(false)
        /// }
        completionHandler(true)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        TRACE("ack: \(ack)")

        if ack == .accept {
            mqtt.subscribe("mom")
            
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        TRACE("new state: \(state)")
        //(window?.rootViewController as? ViewController)?.statusLabel?.text = "status: \(state)"
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        TRACE("message: \(message.string.description), id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        TRACE("id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        TRACE("message: \(message.string.description), id: \(id)")
        //(window?.rootViewController as? ViewController)?.mqttLabel?.text = message.string
        // Only send one notification even if multiple messages are received
        print("Message reveived")
        if shouldSendNotification(msg: message.string!) {
            //sendNotification(msg: message.string ?? "nothing")
            scheduleNotification(msg: message.string ?? "nothing")
        }
        
        backgroundMessageReceived = true
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        TRACE("subscribed: \(success), failed: \(failed)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topics: [String]) {
        TRACE("topic: \(topics)")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        TRACE()
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        TRACE()
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        TRACE("\(err.description)")
    }
}

extension AppDelegate: UITabBarControllerDelegate {
    // Prevent automatic popToRootViewController on double-tap of UITabBarController
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return viewController != tabBarController.selectedViewController
    }
}

extension AppDelegate {
    func TRACE(_ message: String = "", fun: String = #function) {
        let names = fun.components(separatedBy: ":")
        var prettyName: String
        if names.count == 2 {
            prettyName = names[0]
        } else {
            prettyName = names[1]
        }
        
        if fun == "mqttDidDisconnect(_:withError:)" {
            prettyName = "didDisconnect"
        }

        print("[TRACE] [\(prettyName)]: \(message)")
    }
}

extension Optional {
    // Unwrap optional value for printing log only
    var description: String {
        if let self = self {
            return "\(self)"
        }
        return ""
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}
