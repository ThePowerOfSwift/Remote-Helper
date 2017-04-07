//
//  Page.swift
//  Remote Helper
//
//  Created by Venj Chu on 2017/4/2.
//  Copyright © 2017年 Home. All rights reserved.
//

import Foundation
import Fuzi
import Darwin.POSIX.iconv

struct Page {
    var pageLink: String
    var bangumiLinks: [[String: String]]
    var nextPageLink: String?
    var isLastPage: Bool {
        get {
            return (nextPageLink == nil)
        }
    }

    static func parse(data: Data, pageLink: String, isGBK: Bool = false) -> Page? {
        guard let html = isGBK ? (data as NSData).convertToUTF8String(fromEncoding: "GBK", allowLoosy: true) : String(data: data, encoding: .utf8) else { return nil }
        var bangumiLinks: [[String: String]] = []
        var nextPageLink: String? = nil
        do {
            // get bangumi links
            let doc = try HTMLDocument(string: html, encoding: .utf8)
            doc.css("div.co_content8 table td a.ulink").forEach({ (element) in
                var bangumiLink: [String: String] = [:]
                guard let link = element["href"] else { return }
                if link.contains("index.html") || String(link.characters.last!) == "/" { return }
                let title = element.stringValue
                bangumiLink["title"] = title
                bangumiLink["link"] = link
                bangumiLinks.append(bangumiLink)
            })
            // get next page
            doc.css("div.x a").forEach({ (element) in
                if element.stringValue == "下一页" {
                    guard let link = element["href"] else { return }
                    let url = URL(string: pageLink)!
                    if link.characters.first != "/".characters.first {
                        nextPageLink = url.deletingLastPathComponent().appendingPathComponent(link).absoluteString
                    }
                    else {
                        nextPageLink = url.scheme! + "://" + url.host! + "/" + link
                    }

                }
            })

        } catch let error {
            print(error.localizedDescription)
        }

        let page = Page(pageLink: pageLink, bangumiLinks: bangumiLinks, nextPageLink: nextPageLink)
        return page
    }
}

