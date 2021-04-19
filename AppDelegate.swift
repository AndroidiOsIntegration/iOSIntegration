//
//  AppDelegate.swift
//  DemoApp
//

import UIKit
import CoreData

import MessangiSDK

//Libreria para mostrar las notificaciones
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessangiProtocol{

    var window: UIWindow?

    //Registrar permisos parea recibir notificaciones
    func registerForRemoteNotification(){
        if #available(iOS 10.0, *){
            let center = UNUserNotificationCenter.current()
            center.delegate =  self
            center.requestAuthorization(options: [.alert, .sound, .badge]) {
                (granted, error) in
                if !granted {
                    self.getNotificationSettings()
                    print("Something went wrong")
                }
            }
            UIApplication.shared.registerForRemoteNotifications()
        } else if #available(iOS 9, *) {
            UIApplication.shared.registerForRemoteNotifications()
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        } else if #available(iOS 8, *){
            UIApplication.shared.registerForRemoteNotifications()
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
        }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // Configuracion de MessangiSDK
        Messangi.sharedInstance().delegate = self
        Messangi.configure()
        Messangi.sharedInstance().register(withUserID: "Betza1234567")

        //Register APNS
        //Solicitar permiso para recibir notificaciones
        registerForRemoteNotification()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        Messangi.sharedInstance().getUnreadMessages(handler: nil)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    //iOS 9 and lower
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        Messangi.sharedInstance().registerDeviceToken(deviceToken as Data?)
    }
    
    //iOS 10.0
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messangi.sharedInstance().registerDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Remote notification support is unavailable ", error)
    }

    // iOS9
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Messangi.sharedInstance().processRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
    }
    
    
    
   @available(iOS 10.0,*)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        //Se invoca cuando se envía una notificación a una aplicación de primer plano.
        let userInfo = notification.request.content.userInfo
        Messangi.sharedInstance().processRemoteNotification(userInfo, fetchCompletionHandler: nil)
        //Si desea mostrar una notificacion en primer plano, descomente la siguiente linea
        //completionHandler([.alert, .sound])
    }
    
    @available(iOS 10.0, *)
    private func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        //Se le llamó para que su aplicación supiera qué acción seleccionó el usuario para una notificación determinada.
        let userInfo = response.notification.request.content.userInfo
        Messangi.sharedInstance().processRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
    }
    
    func pushReceived(_ message: Message, from workspace:Workspace) {        
        // This method will be called every time the user receives a push notification
        // via library and the field title and body has been retrieved from the server.
        // Use this method to display the content of the notification.
    }
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "DemoApp")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}
