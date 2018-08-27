//
//  RSSFeed.swift
//  App
//
//  Created by Moritz Sternemann on 25.10.17.
//

import Vapor
import Foundation

struct RSSFeedGenerator {

    let xmlStart = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<rss xmlns:dc=\"https://purl.org/dc/elements/1.1/\" xmlns:itunes=\"https://www.itunes.com/dtds/podcast-1.0.dtd\" version=\"2.0\">\n<channel>\n"
    let xmlEnd = "</channel>\n</rss>"
    let dateFormatter: DateFormatter
    let baseLink: String

    // MARK: - Initializer

    init(baseLink: String = "https://homekitty.world") {
        self.baseLink = baseLink
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    }

    // MARK: - Accessories Feed

    func generateFeed(_ req: Request, accessories: [Accessory], manufacturers: [Manufacturer]) throws -> Future<String> {
        var xmlFeed = xmlStart + getXMLMeta()

        // Find when the last accessory was added.
        if let lastAccessory = accessories.first {
            xmlFeed += "<pubDate>\(dateFormatter.string(from: lastAccessory.date))</pubDate>\n"
        }

        for accessory in accessories {
            xmlFeed += rssString(for: accessory, manufacturer: manufacturers.first(where: { $0.id == accessory.id }))
        }

        xmlFeed += xmlEnd
        return req.eventLoop.newSucceededFuture(result: xmlFeed)
    }

    private func rssString(for accessory: Accessory, manufacturer: Manufacturer?) -> String {
        var entry = "<item>\n"
        entry += "<title>\(accessory.name)</title>\n"
        entry += "<description>\n<![CDATA[\n"
        if let imageURL = URL(string: accessory.image, relativeTo: URL(string: baseLink)) {
            entry += "<img src=\"\(imageURL.absoluteString)\" />\n"
        }
        if let price = accessory.price {
            entry += "Price: $\(String(format: "%.2f", price))\n"
        } else {
            entry += "Price: N/A\n"
        }
        if let manufacturer = manufacturer {
            entry += "<p><a href=\"\(baseLink)/manufacturers/\(accessory.manufacturerId)\">By \(manufacturer.name)</a></p>\n"
        }
        if !accessory.released {
            entry += "<i>Accessory or HomeKit support will be released soon.</i>\n"
        }
        entry += "]]></description>\n"
        entry += "<link>\(accessory.productLink)</link>\n"
//        if let category = try category.get() {
//            entry += "<category>\(category.name)</category>\n"
//        }
        entry += "<pubDate>\(dateFormatter.string(from: accessory.date))</pubDate>\n"
        entry += "</item>\n"

        return entry
    }

    private func getXMLMeta() -> String {
        return
            "<title>HomeKitty</title>" +
            "<icon>https://homekitty.world/mstile-150x150.png</icon>" +
            "<logo>https://homekitty.world/mstile-150x150.png</logo>" +
            "<link>https://homekitty.world/</link>" +
            "<description>All HomeKit accessories in a single place.</description>" +
            "<generator>HomeKitty</generator>" +
            "<ttl>60</ttl>" +
            "<copyright>https://homekitty.world/about</copyright>"
    }
}
