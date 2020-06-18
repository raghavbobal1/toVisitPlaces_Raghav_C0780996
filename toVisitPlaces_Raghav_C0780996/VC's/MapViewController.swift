import UIKit
import MapKit

class MapViewController: UIViewController, CLLocationManagerDelegate {
    // Outlet Creation and Variables
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var btnZoomIn: UIButton!
    @IBOutlet weak var btnZoomOut: UIButton!
    @IBOutlet weak var btnNav: UIButton!
    @IBOutlet weak var btnWalk: UIButton!
    @IBOutlet weak var btnCar: UIButton!
    
    var transportType: MKDirectionsTransportType = MKDirectionsTransportType.walking
    var locationManager = CLLocationManager()
    var latitude: CLLocationDegrees??
    var longitude: CLLocationDegrees??
    var location: CLLocation?
    
    var favoritePlaces: [FavoritePlace]?
    
    var favoriteAddress: String?
    var favLocation: CLLocation?
    let defaults = UserDefaults.standard
    var lat: Double = 0.0
      var long: Double = 0.0
      var drag: Bool = false
      
    
        override func viewDidLoad()
        {
            super.viewDidLoad()
            
            mapView.delegate = self
            locationManager.delegate = self
            
            locationManager.requestWhenInUseAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = kCLDistanceFilterNone
            locationManager.startUpdatingLocation()
            
            mapView.showsUserLocation = true
            mapView.isZoomEnabled = false

            addDoubleTap()
            loadData()
            
      }
    
    
     func getDataFilePath() -> String
            {
                //Getting path to txt file
                let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let filePath = documentPath.appending("/places-data.txt")
                return filePath
            }
                
            func loadData()
            {
                favoritePlaces = [FavoritePlace]()
                    
                let filePath = getDataFilePath()
                    
                if FileManager.default.fileExists(atPath: filePath)
                {
                    do
                      {
                        //Reading content from file path string
                         let fileContent = try String(contentsOfFile: filePath)
                         let contentArray = fileContent.components(separatedBy: "\n")
                         for content in contentArray
                         {
                               
                            let placeContent = content.components(separatedBy: ",")
                            if placeContent.count == 6
                                {
                                    let place = FavoritePlace(placeLat: Double(placeContent[0]) ?? 0.0, placeLong: Double(placeContent[1]) ?? 0.0, placeName: placeContent[2], city: placeContent[3], postalCode: placeContent[4], country: placeContent[5])
                                    favoritePlaces?.append(place)
                                }
                         }
                      }
                        catch
                        {
                            print(error)
                        }
                 }
             }
                
            override func prepare(for segue: UIStoryboardSegue, sender: Any?)
            {
                if let sbPlacesList = segue.destination as? FavouritesViewController{
                sbPlacesList.places = self.favoritePlaces
            }
    }
                
                 
            func saveData()
            {
                let filePath = getDataFilePath()
                var saveString = ""
                for place in favoritePlaces!
                {
                    saveString = "\(saveString)\(place.placeLat),\(place.placeLong),\(place.placeName),\(place.city),\(place.country),\(place.postalCode)\n"
                         do
                         {
                            try saveString.write(toFile: filePath, atomically: true, encoding: .utf8)
                         }
                         catch
                         {
                             print(error)
                         }
                }
            }
        
    
        func addDoubleTap()
        {
            let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
                   tap.numberOfTapsRequired = 2
                   mapView.addGestureRecognizer(tap)
        }
    
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
        {
            location = locations.first!
            let coordinateRegion = MKCoordinateRegion(center: location!.coordinate, latitudinalMeters: 1000, longitudinalMeters:1000)
            mapView.setRegion(coordinateRegion, animated: true)
            locationManager.stopUpdatingLocation()
        }
    
        @objc func doubleTapped(sender: UITapGestureRecognizer)
        {
            let locationInView = sender.location(in: mapView)
            let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
            addAnnotation(location: locationOnMap)
            getLocationInfo()
        }

        func addAnnotation(location: CLLocationCoordinate2D)
        {

            self.mapView.removeOverlays(self.mapView.overlays)
            let oldAnnotations = self.mapView.annotations
            self.mapView.removeAnnotations(oldAnnotations)
            

            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            latitude = annotation.coordinate.latitude
            longitude = annotation.coordinate.longitude
            annotation.title = "Your Destination"
            
            self.mapView.addAnnotation(annotation)
        }
   
            @IBAction func navigation(_ sender: Any)
            {
            routeMapping()
            }
    
    func enableLocationServicesAlert()
    {
        //Alert when location services are not enabled
        let alertController = UIAlertController(title: "Error", message:
        "Please enable the access to location services in settings", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))

        self.present(alertController, animated: true, completion: nil)
    }
    func routeMapping()
    {
            self.mapView.removeOverlays(self.mapView.overlays)
            //Getting desination locations
        let request = MKDirections.Request()
        if(location?.coordinate.longitude == nil || location?.coordinate.latitude == nil)
        {
            enableLocationServicesAlert()
            return
        }
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!), addressDictionary: nil))
        //Handling case when no marker is placed
        
        if(latitude == nil || longitude == nil)
        {
                let alertController = UIAlertController(title: "Error", message:
                "Select a destination", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))

                self.present(alertController, animated: true, completion: nil)
        }
        else
        {
                //Getting destination location
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude as! CLLocationDegrees, longitude: longitude as! CLLocationDegrees), addressDictionary: nil))
                request.requestsAlternateRoutes = false
        }
      
        if transportType==MKDirectionsTransportType.walking
        {
            request.transportType = .walking
        }
        else{
            request.transportType = .automobile
        }
        
        
        let directions = MKDirections(request: request)

        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }

            for route in unwrappedResponse.routes {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    //Adding overlays
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.purple
        //Polyline style for automobile route
        if(transportType==MKDirectionsTransportType.automobile)
        {
            renderer.lineWidth = 3;
        }
        //Polyline style for the on foot route
        if(transportType==MKDirectionsTransportType.walking)
        {
            renderer.lineWidth = 4.0
            renderer.lineDashPhase = 5
            renderer.lineDashPattern = [NSNumber(value: 1),NSNumber(value:6)]
        }
        return renderer
    }
    
    @IBAction func btnWalkRoute(_ sender: Any)
    {
        transportType = MKDirectionsTransportType.walking
        routeMapping()
    }
    
    
    @IBAction func btnCarRoute(_ sender: Any)
    {
        transportType = MKDirectionsTransportType.automobile
        routeMapping()
    }
    
    //Zoom in feature
        @IBAction func zoomIn(_ sender: Any)
        {
            var region: MKCoordinateRegion = mapView.region
            region.span.latitudeDelta /= 2.0
            region.span.longitudeDelta /= 2.0
            mapView.setRegion(region, animated: true)
        }
    
        //Zoom out feature
        @IBAction func zoomOut(_ sender: Any)
        {
            var region: MKCoordinateRegion = mapView.region
            region.span.latitudeDelta = min(region.span.latitudeDelta * 2.0, 180.0)
            region.span.longitudeDelta = min(region.span.longitudeDelta * 2.0, 180.0)
            mapView.setRegion(region, animated: true)
        }
        
        func getLocationInfo()
        {
            var location = CLLocation(latitude: latitude as! CLLocationDegrees, longitude: longitude as! CLLocationDegrees) //changed!!!
            print(location)

    CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
        print(location)
        guard error == nil else {
            print("Reverse geocoder failed with error" + error!.localizedDescription)
            return
        }
        guard placemarks!.count > 0 else {
            print("Problem with the data received from geocoder")
            return
        }
        let pm = placemarks![0] as! CLPlacemark
        print(pm.locality!)
        print(pm.thoroughfare!)
        print(pm.postalCode!)
    })
        }
    
    
    func getFavLocation()
    {
    //Using reverse geolocation to get address information
    CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitude as! CLLocationDegrees, longitude: longitude as! CLLocationDegrees)) {  placemark, error in
      if let error = error as? CLError
      {
          print("CLError:", error)
          return
      }
      else if let placemark = placemark?[0]
      {
       
       var placeName = ""
       var city = ""
       var postalCode = ""
       var country = ""
       
       // Getting address information from placemarks
       if let name = placemark.name { placeName += name }
       if let locality = placemark.subLocality { city += locality }
       if let code = placemark.postalCode { postalCode += code }
       if let country_pc = placemark.country { country += country_pc }

        let place = FavoritePlace(placeLat: self.latitude as! Double, placeLong:self.longitude as! Double, placeName: placeName, city: city, postalCode: postalCode, country: country)
     
       self.favoritePlaces?.append(place)
       self.saveData()
       self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
}
