//
//  RiderApp.swift
//  Rider
//
//  Created by zhongyu deng on 2024/11/16.
//

import SwiftUI
import GoogleMaps
import GooglePlaces


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        GMSServices.provideAPIKey("AIzaSyBGw2-b0jxmpvTVmTCz5lQSq-dvtw24Rvc")
                GMSPlacesClient.provideAPIKey("AIzaSyBGw2-b0jxmpvTVmTCz5lQSq-dvtw24Rvc")
        return true
    }
}

@main
struct RiderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
