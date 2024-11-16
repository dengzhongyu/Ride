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
    @State private var remainingDistance: Double = 0
    @State private var estimatedTime: TimeInterval = 0
    @State private var isNavigating = false // 是否正在导航

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

            Button(action: startNavigation) {
                Text(isNavigating ? "riding..." : "start riding")
                    .padding()
                    .background(isNavigating ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(isNavigating) // 禁用按钮以防重复点击
        }
        .onChange(of: locationManager.currentLocation) { newLocation in
            if let newLocation = newLocation, isNavigating {
                updateRoute(from: newLocation.coordinate)
                updateRideInfo(newLocation: newLocation)
            }
        }
    }

    func startNavigation() {
        guard let destination = selectedDestination, let startLocation = locationManager.currentLocation else {
            infoLabelText = "请先选择目的地"
            return
        }
        isNavigating = true // 标记为正在导航
        actualPath = GMSMutablePath() // 清空实际路径
        calculateRoute(from: startLocation.coordinate, to: destination)
    }

    func updateRoute(from start: CLLocationCoordinate2D) {
        guard let destination = selectedDestination else { return }
        calculateRoute(from: start, to: destination)
    }

    func calculateRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) {
        let origin = "\(start.latitude),\(start.longitude)"
        let destination = "\(end.latitude),\(end.longitude)"
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=bicycling&key=YOUR_GOOGLE_MAPS_API_KEY"

        URLSession.shared.dataTask(with: URL(string: url)!) { data, _, error in
            guard error == nil, let data = data else { return }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                if let routes = json["routes"] as? [[String: Any]], let route = routes.first {
                    if let overviewPolyline = route["overview_polyline"] as? [String: Any],
                       let points = overviewPolyline["points"] as? String {
                        DispatchQueue.main.async {
                            self.drawPlannedRoute(from: points)
                            
                            if let legs = route["legs"] as? [[String: Any]], let leg = legs.first,
                               let distance = leg["distance"] as? [String: Any],
                               let value = distance["value"] as? Double {
                                self.remainingDistance = value
                            }
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
        guard let destination = selectedDestination else { return }

        // 记录实际路径
        actualPath.add(newLocation.coordinate)

        // 更新剩余距离
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        remainingDistance = newLocation.distance(from: destinationLocation)

        // 实时更新预计时间
        if remainingDistance > 0 {
            let speed = 5.0 // 假设速度为 5 米/秒（自行车平均速度）
            estimatedTime = remainingDistance / speed
        }

        // 更新信息文本
        let remainingTimeText = formatTimeInterval(estimatedTime)
        infoLabelText = """
        剩余距离：\(String(format: "%.2f", remainingDistance / 1000)) km
        预计时间：\(remainingTimeText)
        """
    }

    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}



#Preview {
    ContentView()
}
