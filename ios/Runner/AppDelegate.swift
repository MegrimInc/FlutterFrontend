import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        UNUserNotificationCenter.current().delegate = self //I ADDED THIS
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
    // ALL OF THE STUFF BELOW HERE I ADDED
    //--------------------------------------------------------------------------------------------------------------------------------
    //Foreground
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Foreground notification received: \(notification.request.content.userInfo)")
        completionHandler([.alert, .sound])
    }
    //Background
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("User tapped notification with data: \(userInfo)")
        if let flutterVC = window?.rootViewController as? FlutterViewController {
            let methodChannel = FlutterMethodChannel(name: "com.barzzy/notification", binaryMessenger: flutterVC.binaryMessenger)
            methodChannel.invokeMethod("navigateToOrders", arguments: nil)
        }
        completionHandler()
    //----------------------------------------------------------------------------------------------------------------------------------
    }
}
