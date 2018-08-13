//
//  ReportResponse.swift
//  App
//
//  Created by Kim de Vos on 13/08/2018.
//

import Foundation

public struct ReportResponse: Codable {
    let accessories: [Accessory]
    let apps: [HomekitApp]
    let accessoryToReport: Accessory.AccessoryResponse?
    let appToReport: HomekitApp?
}
