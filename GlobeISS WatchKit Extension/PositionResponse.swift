//
//  PositionResponse.swift
//  GlobeISS WatchKit Extension
//
//  Created by Dylan Maryk on 03/05/2020.
//  Copyright © 2020 Dylan Maryk. All rights reserved.
//

struct PositionResponse: Decodable {
    let issPosition: Position
}

struct Position: Decodable {
    let latitude: String
    let longitude: String
}
