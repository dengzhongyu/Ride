//
//  ContentView.swift
//  Rider
//
//  Created by zhongyu deng on 2024/11/16.
//

import SwiftUI
import GoogleMaps
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var selectedDestination: CLLocationCoordinate2D?
    @State private var plannedRoutePolyline: GMSPolyline?
    @State private var actualPath = GMSMutablePath()
    @State private var infoLabelText = "选择目的地"
    @State private var totalDistance: Double = 0
    @State private var remainingDistance: String = ""
    @State private var estimatedTime: String = ""
    @State private var isNavigating = false // 是否正在导航
    var mapView: GoogleMapView?

    var body: some View {
        VStack {
            GoogleMapView(
                selectedDestination: $selectedDestination,
                plannedRoutePolyline: $plannedRoutePolyline,
                actualPath: $actualPath,
                currentLocation: locationManager.currentLocation,
                isNavigating: $isNavigating
            )
            .edgesIgnoringSafeArea(.top)

            Text(infoLabelText)
                .padding()

            Button(action: navigateAction) {
                Text(isNavigating ? "结束骑行" : "开始骑行")
                    .padding()
                    .background(isNavigating ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .onChange(of: locationManager.currentLocation) { newLocation in
            if let newLocation = newLocation, isNavigating {
                updateRoute(from: newLocation.coordinate)
                updateRideInfo(newLocation: newLocation)
            }
        }
        .onChange(of: isNavigating) { newValue in
                    if !newValue {
                        clearMap()
                    }
                }
    }
    
    func clearMap() {
            // 清除规划路线
            plannedRoutePolyline?.map = nil
            plannedRoutePolyline = nil

            // 清空实际路径
            actualPath = GMSMutablePath()

            // 清空目的地
            selectedDestination = nil

            // 更新信息文本
            infoLabelText = "选择目的地"
        
            // 清除目的地标记
            mapView.removeMarker() // 让 GoogleMapView 清除标记
        }
    
    func navigateAction() {
        
        guard let destination = selectedDestination, let startLocation = locationManager.currentLocation else {
            infoLabelText = "请先选择目的地"
            return
        }
        isNavigating = !isNavigating
        actualPath = GMSMutablePath() // 清空实际路径
        if (isNavigating) {
            calculateRoute(from: startLocation.coordinate, to: destination)
        }
    }

    func updateRoute(from start: CLLocationCoordinate2D) {
        guard let destination = selectedDestination else { return }
        calculateRoute(from: start, to: destination)
    }

    func calculateRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) {
        let origin = "\(start.latitude),\(start.longitude)"
        let destination = "\(end.latitude),\(end.longitude)"
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=bicycling&key=AIzaSyBGw2-b0jxmpvTVmTCz5lQSq-dvtw24Rvc"

        URLSession.shared.dataTask(with: URL(string: url)!) { data, _, error in
            guard error == nil, let data = data else { return }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                if let routes = json["routes"] as? [[String: Any]], let route = routes.first {
                    if let overviewPolyline = route["overview_polyline"] as? [String: Any],
                       let points = overviewPolyline["points"] as? String {
                        DispatchQueue.main.async {
                            self.drawPlannedRoute(from: points)
                            print("route info: \(route)")
                            if let legs = route["legs"] as? [[String: Any]], let leg = legs.first,
                               let distance = leg["distance"] as? [String: Any],
                               let value = distance["text"] as? String {
                                self.remainingDistance = value
                            }
                            if let legs = route["legs"] as? [[String: Any]], let leg = legs.first,
                               let duration = leg["duration"] as? [String: Any],
                               let value = duration["text"] as? String {
                                self.estimatedTime = value
                            }
                            self.updateRideInfo(newLocation: self.locationManager.currentLocation ?? CLLocation(latitude: 37.785834, longitude: -122.406417))
                        }
                    }
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }.resume()
    }

    func drawPlannedRoute(from encodedPath: String) {
        if let path = GMSPath(fromEncodedPath: encodedPath) {
            plannedRoutePolyline?.map = nil // 清除旧路线
            plannedRoutePolyline = GMSPolyline(path: path)
            plannedRoutePolyline?.strokeColor = .blue
            plannedRoutePolyline?.strokeWidth = 4.0
            plannedRoutePolyline?.map = nil // Reset to nil
        }
    }

    func updateRideInfo(newLocation: CLLocation) {
        // 记录实际路径
        actualPath.add(newLocation.coordinate)


        // 更新信息文本
        infoLabelText = """
        剩余距离：\(remainingDistance)
        预计时间：\(estimatedTime)
        """
    }
}



#Preview {
    ContentView()
}
