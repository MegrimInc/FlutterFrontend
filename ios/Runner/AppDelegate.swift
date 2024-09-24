import UIKit
import Flutter
import flutter_local_notifications
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Configure Firebase
    FirebaseApp.configure()

    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    // Request notification permissions
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { granted, error in
        if let error = error {
          print("Error requesting notification authorization: \(error)")
        }
      }
    )

    // Set the delegate to self to handle foreground and background notifications
    UNUserNotificationCenter.current().delegate = self

    // FlutterLocalNotificationsPlugin setup for background notifications
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle notifications while the app is in the foreground
  @available(iOS 10.0, *)
  override public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                              willPresent notification: UNNotification,
                                              withCompletionHandler completionHandler:
                                              @escaping (UNNotificationPresentationOptions) -> Void) {
    // Show notifications in the foreground
    completionHandler([.alert, .badge, .sound])
  }

  // Handle notification taps in the background or when the app is terminated
  @available(iOS 10.0, *)
  override public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                              didReceive response: UNNotificationResponse,
                                              withCompletionHandler completionHandler: @escaping () -> Void) {
    // You don't need to handle navigation here—Flutter will handle this via Dart.
    // Simply pass the payload to the Dart side to handle.

    // For now, we pass the payload to Flutter to handle.
    completionHandler()
  }
}
