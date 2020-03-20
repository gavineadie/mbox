//
//  Message.swift
//
//
//  Created by Gavin Eadie on 1/20/20.
//

import Foundation
import Files

let usefulHeaders = ["from:", "date:", "subject:", "to:", "cc:", "bcc:", "mime-version:",
                     "content-type:", "message-id:", "resent-to:", "x-error:", "x-sender:"]

let specialHeaders = ["x-gmail-labels:", "received:"]

let uselessHeaders = ["x-gm-thrid:", "delivered-to:", "x-attachments:",
                      "content-transfer-encoding:", "in-reply-to:", "mime-version:"]

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
            .replacingOccurrences(of: "\n ", with: "")
            .components(separatedBy: "\n").filter( { header in header.count > 0 } )

        var tempHeadDict = [String : String]()
        tempHeaders.forEach( { header in
            let splitHeader = header.split(separator: " ", maxSplits: 1)
            if splitHeader.count == 2 {
                let headerKey = String(splitHeader[0].lowercased())
                let headerText = String(splitHeader[1])

                // treat some headers that are duplicated specially:
                //      "delivered-to:",                        <-- treat normally
                //      "message-id:",                          <-- treat normally
                //      "x-gm-thrid:"                           <-- treat normally

                //      "x-gmail-labels:",                      <-- accumulate values with commas
                //      "received:"                             <-- accumulate values with space

                if "x-gmail-labels:".contains(headerKey) {
                    if let previousText = tempHeadDict.updateValue(headerText, forKey: headerKey) {
                        tempHeadDict.updateValue(previousText + "," + headerText, forKey: headerKey)
                    }
                } else if "received:".contains(headerKey) {
                    if let previousText = tempHeadDict.updateValue(headerText, forKey: headerKey) {
                        tempHeadDict.updateValue(previousText + " " + headerText, forKey: headerKey)
                    }
                } else {
                    tempHeadDict.updateValue(headerText, forKey: headerKey)
                }
            } else {

                // possible key-only header: "Bcc:", "Cc:", "X-Attachments:"    <-- delete these

            }
        })

        self.headDict = tempHeadDict

        self.bodyText = String(entireMessage[headBodyDivision.lowerBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

// FIXME: -- copy the date from the original file (some are good)

    func emit(file: File) throws {
        try file.append("\r\nFrom xxx@xxx Thu Dec 31 23:59:59 +0000 2020\n")
        try self.headDict.forEach( { key, value in
            if usefulHeaders.contains(key) || specialHeaders.contains(key) {
                try file.append(key + " " + value + "\n")
            }
        } )
        try file.append("\n")
        try file.append(self.bodyText + "\n")
    }

// TODO: gather GMAIL labels (multiple occurences) .. drop "0000" keep others (like "1998")
// TODO: gather "Received:" (multiple occurences)

    mutating func cleanupHeaders() {

        // identify and convert utf-8 symbols

        if var gLabel = headDict["x-gmail-labels:"] {
            if gLabel.contains("=?UTF-8") {

                gLabel = gLabel.replacingOccurrences(of: "=?UTF-8?Q?", with: "UTF8,")
                gLabel = gLabel.replacingOccurrences(of: "=E2=80=A2", with: "•")
                gLabel = gLabel.replacingOccurrences(of: "?=", with: "")

                headDict.updateValue(gLabel, forKey: "x-gmail-labels:")
            }
        }

        // lowercase "From:" addresses inside <   >

        if var fromAddress = headDict["from:"] {

            fromAddress = fromAddress.replacingOccurrences(of: "Gavin@UMich.EDU",
                                                           with: "gavin@umich.edu",
                                                           options: .caseInsensitive)
            headDict.updateValue(fromAddress, forKey: "from:")

        }
    }
}
