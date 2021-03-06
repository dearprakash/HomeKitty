//
//  Copyright © 2018 HomeKitty. All rights reserved.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class Accessory: PostgreSQLModel {

    static var entity = "accessories"

    var id: Int?
    var categoryId: Int
    var manufacturerId: Int
    var requiredHubId: Int?

    var name: String
    var image: String
    var price: Double?
    var productLink: String
    var amazonLink: String?
    var approved: Bool
    var released: Bool
    var date: Date
    var requiresHub: Bool
    var featured: Bool
    var supportsAirplay2: Bool

    init(
        name: String,
        image: String,
        price: Double?,
        productLink: String,
        amazonLink: String?,
        categoryId: Int,
        manufacturerId: Int,
        released: Bool,
        requiresHub: Bool,
        requiredHubId: Int?,
        supportsAirplay2: Bool) {
        self.name = name
        self.categoryId = categoryId
        self.manufacturerId = manufacturerId
        self.image = image
        self.price = price
        self.productLink = productLink
        self.amazonLink = amazonLink
        self.approved = false
        self.released = released
        self.date = Date()
        self.requiresHub = requiresHub
        self.requiredHubId = requiredHubId
        self.featured = false
        self.supportsAirplay2 = supportsAirplay2
    }

    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case manufacturerId = "manufacturer_id"
        case requiredHubId = "required_hub_id"

        case name
        case image
        case price
        case productLink = "product_link"
        case amazonLink = "amazon_link"
        case approved
        case released
        case date
        case requiresHub = "requires_hub"
        case featured
        case supportsAirplay2 = "supports_airplay_2"
    }

    var category: Parent<Accessory, Category> {
        return parent(\Accessory.categoryId)
    }

    var manufacturer: Parent<Accessory, Manufacturer> {
        return parent(\Accessory.manufacturerId)
    }

    var requiredHub: Parent<Accessory, Accessory>? {
        return parent(\Accessory.requiredHubId)
    }
    
    var regions: Siblings<Accessory, Region, AccessoryRegionPivot> {
        return siblings()
    }

    func regionCompatibility(_ req: Request) throws -> Future<String> {
        return try regions.query(on: req).all().flatMap(to: String.self) { regions in
            let promise = req.eventLoop.newPromise(String.self)
            promise.succeed(result: regions.map { $0.name }.joined(separator: ", "))
            return promise.futureResult
        }
    }

    struct FeaturedResponse: Codable {
        let name: String
        let externalLink: String
        let bannerImage: String
    }

    struct AccessoryResponse: Codable {
        let id: Int?
        let name: String
        let image: String
        let price: String?
        let productLink: String
        let categoryId: Int
        let amazonLink: String?
        let approved: Bool
        let released: Bool
        let date: Date
        let requiresHub: Bool
        let featured: Bool
        let manufacturerId: Int?
        let manufacturerName: String?
        let manufacturerWebsite: String?
        let timeAgo: String?
        let supportsAirplay2: Bool

        init(accessory: Accessory, manufacturer: Manufacturer) {
            id = accessory.id
            name = accessory.name
            image = accessory.image
            if let accessoryPrice = accessory.price {
                price = String(format: "%.2f", accessoryPrice)
            } else {
                price = nil
            }
            productLink = accessory.productLink
            categoryId = accessory.categoryId
            amazonLink = accessory.amazonLink
            approved = accessory.approved
            released = accessory.released
            date = accessory.date
            requiresHub = accessory.requiresHub
            featured = accessory.featured
            manufacturerId = accessory.manufacturerId
            manufacturerName = manufacturer.name
            manufacturerWebsite = manufacturer.websiteLink
            timeAgo = accessory.date.timeAgoString()
            supportsAirplay2 = accessory.supportsAirplay2
        }

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case image
            case price
            case productLink = "product_link"
            case amazonLink = "amazon_link"
            case approved
            case released
            case date
            case requiresHub = "requires_hub"
            case featured
            case manufacturerId = "manufacturer_id"
            case manufacturerName = "manufacturer_name"
            case timeAgo = "time_ago"
            case manufacturerWebsite = "manufacturer_website"
            case categoryId = "category_id"
            case supportsAirplay2 = "supports_airplay_2"
        }
    }
}

extension Accessory: PostgreSQLMigration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection, closure: { builder in
            builder.field(for: \Accessory.id, type: .int, .primaryKey())
            builder.field(for: \Accessory.name)
            builder.field(for: \Accessory.image)
            builder.field(for: \Accessory.price)
            builder.field(for: \Accessory.productLink)
            builder.field(for: \Accessory.categoryId)
            builder.field(for: \Accessory.amazonLink)
            builder.field(for: \Accessory.approved)
            builder.field(for: \Accessory.released)
            builder.field(for: \Accessory.date)
            builder.field(for: \Accessory.requiresHub)
            builder.field(for: \Accessory.requiredHubId)
            builder.field(for: \Accessory.featured)
            builder.field(for: \Accessory.manufacturerId)
            builder.field(for: \Accessory.supportsAirplay2)
            builder.reference(from: \Accessory.requiredHubId, to: \Accessory.id)
            builder.reference(from: \Accessory.categoryId, to: \Category.id)
            builder.reference(from: \Accessory.manufacturerId, to: \Manufacturer.id)
        })
    }
}
