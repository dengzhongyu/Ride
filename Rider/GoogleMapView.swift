//
//  GoogleMapView.swift
//  Rider
//
//  Created by zhongyu deng on 2024/11/16.
//

import SwiftUI
import GoogleMaps

struct GoogleMapView: UIViewControllerRepresentable {
    @Binding var selectedDestination: CLLocationCoordinate2D?
    @Binding var plannedRoutePolyline: GMSPolyline?
    @Binding var actualPath: GMSMutablePath
    var currentLocation: CLLocation?
    @Binding var isNavigating: Bool

    private class MarkerManager {
        var destinationMarker: GMSMarker?

        func setMarker(at coordinate: CLLocationCoordinate2D, on mapView: GMSMapView) {
            // 移除旧的 marker
            destinationMarker?.map = nil
            // 创建新的 marker
            let newMarker = GMSMarker(position: coordinate)
            newMarker.title = "目的地"
            newMarker.map = mapView
            destinationMarker = newMarker
        }
        
        func removeMarker() {
            // 移除当前的 marker
            destinationMarker?.map = nil
            destinationMarker = nil
        }
    }

    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapView
        private let markerManager = MarkerManager()

        init(parent: GoogleMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            // 如果正在导航，禁止修改目的地
            if parent.isNavigating {
                return
            }
            // 更新目的地
            parent.selectedDestination = coordinate
            // 更新 marker
            markerManager.setMarker(at: coordinate, on: mapView)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let mapView = GMSMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.isMyLocationEnabled = true

        let controller = UIViewController()
        controller.view = mapView
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let mapView = uiViewController.view as? GMSMapView else { return }

        // 更新当前摄像头位置
        if let currentLocation = currentLocation {
            let camera = GMSCameraPosition.camera(withLatitude: currentLocation.coordinate.latitude,
                                                  longitude: currentLocation.coordinate.longitude, zoom: 15)
            mapView.animate(to: camera)
        }

        // 显示规划路线
        if let plannedRoutePolyline = plannedRoutePolyline {
            plannedRoutePolyline.map = mapView
        }

        // 显示实际骑行路径
        if actualPath.count() > 0 {
            let polyline = GMSPolyline(path: actualPath)
            polyline.strokeColor = .green
            polyline.strokeWidth = 4.0
            polyline.map = mapView
        }
    }
}


