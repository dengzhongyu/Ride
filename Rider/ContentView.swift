//
//  ContentView.swift
//  Rider
//
//  Created by zhongyu deng on 2024/11/16.
//

import SwiftUI
import GoogleMaps
import CoreLocation

let MI_TRANSFORM: Double = 0.000621
let API_Key: String = "AIzaSyBGw2-b0jxmpvTVmTCz5lQSq-dvtw24Rvc"

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
        .onChange(of: locationManager.currentLocation) { oldLocation, newLocation in
            if let newLocation = newLocation, isNavigating {
                updateRoute(from: newLocation.coordinate)
                updateRideInfo(newLocation: newLocation)
            }
        }
        .onChange(of: isNavigating) { oldValue, newValue in
                    if !newValue {
                        clearMap()
                    }
                }
    }
    
    func clearMap() {
        // 清除规划路线
        let mapView = plannedRoutePolyline?.map;
        plannedRoutePolyline?.map = nil
        plannedRoutePolyline = nil

        // 清空实际路径
        actualPath = GMSMutablePath()

        // 清空目的地
        selectedDestination = nil

        // 更新信息文本
        infoLabelText = "选择目的地"
    
        // 清除目的地标记
        mapView?.clear()
        
    }

    // 计算实际骑行距离
    func calculateActualDistance() -> Double {
        var distance: Double = 0.0
        for i in 0..<actualPath.count() - 1 {
            let start = actualPath.coordinate(at: i)
            let end = actualPath.coordinate(at: i + 1)
            let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
            let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
            distance += startLocation.distance(from: endLocation)
        }
        return distance
    }
    
    // 是否靠近目的地
    ///   - threshold: 距离阈值（默认 10 米）
    func areLocationsWithinDistance(location1: CLLocation, location2: CLLocation, threshold: Double = 10.0) -> Bool {
        let distance = location1.distance(from: location2)
        return distance <= threshold
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
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=bicycling&key=\(API_Key)"
        print("calculate route:\(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error fetching route: \(error)")
                return
            }

            guard let data = data else {
                print("Error: No data received")
                return
            }

            do {
                // 解析 JSON 数据
                let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                guard let routes = json["routes"] as? [[String: Any]], let route = routes.first else {
                    print("Error: No routes found")
                    return
                }

                // 提取折线数据
                if let overviewPolyline = route["overview_polyline"] as? [String: Any],
                   let points = overviewPolyline["points"] as? String {
                    DispatchQueue.main.async {
                        self.drawPlannedRoute(from: points)
                    }
                }

                // 提取距离和时间信息
                if let legs = route["legs"] as? [[String: Any]], let leg = legs.first {
                    DispatchQueue.main.async {
                        self.extractLegInfo(leg: leg)
                    }
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }.resume()
    }

    // 提取并更新距离和时间信息
    private func extractLegInfo(leg: [String: Any]) {
        if let distance = leg["distance"] as? [String: Any],
           let distanceText = distance["text"] as? String {
            self.remainingDistance = distanceText
        } else {
            print("Error: Distance information missing")
        }

        if let duration = leg["duration"] as? [String: Any],
           let durationText = duration["text"] as? String {
            self.estimatedTime = durationText
        } else {
            print("Error: Duration information missing")
        }

        // 更新实时骑行信息
        if let currentLocation = self.locationManager.currentLocation {
            self.updateRideInfo(newLocation: currentLocation)
        }
    }


    func drawPlannedRoute(from encodedPath: String) {
        if let path = GMSPath(fromEncodedPath: encodedPath) {
            plannedRoutePolyline?.map = nil // 清除旧路线
            plannedRoutePolyline = GMSPolyline(path: path)
            plannedRoutePolyline?.strokeColor = .blue
            plannedRoutePolyline?.strokeWidth = 4.0
        }
    }

    func updateRideInfo(newLocation: CLLocation) {
        // 记录实际路径
        actualPath.add(newLocation.coordinate)
        let ridedDis = calculateActualDistance() * MI_TRANSFORM
        
        let uponDestionDes = areLocationsWithinDistance(location1: newLocation, location2: CLLocation(latitude: selectedDestination!.latitude, longitude: selectedDestination!.longitude)) ? "临近目的地,欢迎下次使用" : ""
        // 更新信息文本
        infoLabelText = """
            \(uponDestionDes)
            已骑行：\((ridedDis * 100).rounded() / 100) mi
            剩余距离：\(remainingDistance)
            预计时间：\(estimatedTime)
        """
    }
}



#Preview {
    ContentView()
}
