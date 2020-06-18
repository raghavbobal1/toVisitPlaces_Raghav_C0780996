//
//  EditMarkerViewController.swift
//  toVisitPlaces_Raghav_C0780996
//
//  Created by Raghav Bobal on 2020-06-17.
//  Copyright © 2020 com.lambton. All rights reserved.
//
import UIKit
import MapKit

class EditMarkerViewController: UIViewController, MKMapViewDelegate {

// Outlets and variables
    
    @IBOutlet weak var editMap: MKMapView!
    let defaults = UserDefaults.standard
    var lat : Double = 0.0
    var long : Double = 0.0
    var drag : Bool? = false
    var editedPlace : Int = 0
    var editPlaces : [FavoritePlace]?

   override func viewDidLoad()
        {
            super.viewDidLoad()
            editMap.delegate = self
            
            self.editedPlace = defaults.integer(forKey: "edit")
                    
            self.editMap.addAnnotation(dragPin())
            let latDelta: CLLocationDegrees = 0.05
            let longDelta: CLLocationDegrees = 0.05
             
             // 3 - Creating the span, location coordinate and region
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
            let customLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
            let region = MKCoordinateRegion(center: customLocation, span: span)
                   
             // 4 - assign region to map
            editMap.setRegion(region, animated: true)
            loadData()
        }
        
       func dragPin() -> MKPointAnnotation
       {
            self.lat = defaults.double(forKey: "latitude")
            self.long = defaults.double(forKey: "longitude")
        
            self.drag = defaults.bool(forKey: "bool")
        
            print("Lat: \(lat): Long: \(long)")
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: self.lat, longitude: self.long)
            annotation.title = "Favorite Location"
            return annotation
        }
         
        func getDataFilePath() -> String
        {
            let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let filePath = documentPath.appending("/places-data.txt")
            return filePath
        }
            
        func loadData()
        {
            self.editPlaces = [FavoritePlace]()
                
            let filePath = getDataFilePath()
                
            if FileManager.default.fileExists(atPath: filePath)
                {
                    do
                    {
                     
                        let fileContent = try String(contentsOfFile: filePath)
                        
                        let contentArray = fileContent.components(separatedBy: "\n")
                        for content in contentArray
                        {
                           
                        let placeContent = content.components(separatedBy: ",")
                        if placeContent.count == 6
                            {
                                let place = FavoritePlace(placeLat: Double(placeContent[0]) ?? 0.0, placeLong: Double(placeContent[1]) ?? 0.0, placeName: placeContent[2], city: placeContent[3], postalCode: placeContent[4], country: placeContent[5])
                                self.editPlaces?.append(place)
                            }
                        }
                    }
                    catch
                    {
                        print(error)
                    }
                }
            }
            
            //Editted path
            func editLocation() {
                let filePath = getDataFilePath()

                var saveString = ""
                for place in self.editPlaces!{
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
    }

extension EditMarkerViewController
{
        
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        
        //Custom draggable pin information
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = UIColor.blue
        pinAnnotation.isDraggable = true
        pinAnnotation.canShowCallout = true
        
        let button = UIButton()
        button.setImage(UIImage(named :"heart")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        pinAnnotation.rightCalloutAccessoryView = button
            
        return pinAnnotation
    }
        
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl)
    {
        let alertController = UIAlertController(title: "Edit Favourite", message: "Are you sure you want to change this location?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Yes", style:  .default, handler: { (UIAlertAction) in
                   
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: mapView.annotations[0].coordinate.latitude, longitude: mapView.annotations[0].coordinate.longitude)) {  placemark, error in
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
                            
                    if let name = placemark.name { placeName += name }
                    if let locality = placemark.subLocality { city += locality }
                    if let code = placemark.postalCode { postalCode += code }
                    if let country_pc = placemark.country { country += country_pc }
                
                    let place = FavoritePlace(placeLat:  mapView.annotations[0].coordinate.latitude, placeLong: mapView.annotations[0].coordinate.longitude, placeName: placeName, city: city, postalCode: postalCode, country: country)
                    self.editPlaces?.remove(at: self.editedPlace)
                    self.editPlaces?.append(place)
                            
                    self.editLocation()
                    self.navigationController?.popToRootViewController(animated: true)
                 }
                }
                   
                }))
           
               alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                   self.present(alertController, animated: true, completion: nil)
        }


}
