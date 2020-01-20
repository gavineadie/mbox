//
//  Message.swift
//  
//
//  Created by Gavin Eadie on 1/20/20.
//

import Foundation
import Files

let usefulHeaders = ["from:", "date:", "subject:", "to:", "cc:", "bcc:",
                     "mime-version:", "content-type:", "message-id:", "resent-to:",
                     "X-Gmail-Labels:", "X-Error:", "X-Sender:", "Received:"]

let uselessHeaders = ["X-GM-THRID:", "Delivered-To:", "X-Attachments:",
                      "Content-Transfer-Encoding:", "In-Reply-To:", "MIME-Version:"]

let messageSeparator = "\r\nFrom "

struct Message {
    var headDict: [String : String]
    var bodyText: String

/*┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
  ┃  convert <CR><LF> to <LF> and search for <LF><LF> as the head/body divider                       ┃
  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛*/
    init?(_ message: String) {
        let entireMessage = message.replacingOccurrences(of: "\r\n", with: "\n")
        guard let headBodyDivision = entireMessage.range(of: "\n\n") else { return nil }

        let tempHeaders = entireMessage[...headBodyDivision.lowerBound]
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\n ", with: " ")
            .components(separatedBy: "\n").filter( { header in header.count > 0 } )

        var tempHeadDict = [String : String]()
        tempHeaders.forEach( { header in
            let splitHeader = header.split(separator: " ", maxSplits: 1)
            if splitHeader.count == 2 {
                tempHeadDict.updateValue(String(splitHeader[1]), forKey: splitHeader[0].lowercased())
            }
        })

        self.headDict = tempHeadDict

        self.bodyText = String(entireMessage[headBodyDivision.lowerBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func print(file: File) throws {
        try file.append("\r\nFrom xxx@xxx Sun Jun 10 23:59:59 +0000 2018\n")    // FIXME: -- copy the date from the original file (some are good)
        try self.headDict.forEach( { key, value in
            if usefulHeaders.contains(key) {
                try file.append(key + " " + value + "\n")
            }
        } )
        try file.append("\n")
        try file.append(self.bodyText + "\n")
    }

}
