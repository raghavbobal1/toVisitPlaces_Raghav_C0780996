//
//  FavPlaces.swift
//  toVisitPlaces_Raghav_C0780996
//
//  Created by Raghav Bobal on 2020-06-17.
//  Copyright © 2020 com.lambton. All rights reserved.
//


import Foundation

class FavoritePlace{
    
    var placeLat: Double
    var placeLong: Double
    var placeName :String
    var city :String
    var postalCode : String
    var country : String
    
    init(placeLat:Double , placeLong: Double, placeName:String, city:String, postalCode: String, country:String) {
        self.placeLat = placeLat
        self.placeLong = placeLong
        self.placeName = placeName
        self.city = city
        self.postalCode = postalCode
        self.country = country
    }
    
    
}
