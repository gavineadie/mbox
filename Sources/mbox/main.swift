//
//  main.swift
//  mboxFileParser
//
//  Created by Gavin Eadie on 6/6/18.
//  Copyright © 2018 Gavin Eadie. All rights reserved.
//

import Foundation
import Files

let homeDirectory = Folder.home

let options = MboxOptions()

/// an MBOX file contains concatenated RFC822 mail messages.  Each starts with a line "From " and
/// ends with a newline .. our first job is to split these out so they can be examined individually.

typealias oneMessage = [String]

print("      start: \(Date())")

let fileNoSndr = try homeDirectory.createFileIfNeeded(at: "Desktop/MBOX/nosend.mbox")
let fileIsAOCE_M = try homeDirectory.createFileIfNeeded(at: "Desktop/MBOX/isaoce-modified.mbox")
let fileIsAOCE_O = try homeDirectory.createFileIfNeeded(at: "Desktop/MBOX/isaoce-original.mbox")
let fileNoRcvr = try homeDirectory.createFileIfNeeded(at: "Desktop/MBOX/norcvr.mbox")
let fileIsRich = try homeDirectory.createFileIfNeeded(at: "Desktop/MBOX/isrich.mbox")

/// in our test "0000" file, there two duplicates: Message-IDs: v04011700b1eba6a321a7 and v04020401b22c63b055e6

let fileToRead = try homeDirectory.file(at: options.inputFile)
let fileNormal = try homeDirectory.createFileIfNeeded(at: options.outputFile)

print("mbox mapped: \(Date())")

do {
    let mboxRecords = try fileToRead.readAsString(encodedAs: .utf8)

    print("mbox String: \(Date())")

    let messages = ("\r\n" + mboxRecords).components(separatedBy: messageSeparator)
    let messageArray = messages.compactMap { message in
        Message(message)
    }

    print(" mbox split: \(Date()) .. \(messageArray.count) messages in file.")

    for var message in messageArray {                                           // ~135 seconds
        var modified = false

        message.cleanupHeaders()            // "UTF-8", ...

// TODO: watch for "<extract>"

        if message.bodyText.contains("<x-flowed>") {
            message.bodyText = message.bodyText
                .replacingOccurrences(of: "<x-flowed>", with: "")   // TODO: what is "x-flowed"?
                .replacingOccurrences(of: "</x-flowed>", with: "")
                .replacingOccurrences(of: "", with: "")
                .replacingOccurrences(of: "", with: "")
            try message.emit(file: fileIsRich)
            continue
        }

/*┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
  ┃ the body contains "RFC822 Header" so we can use these AOCE headers to refine what we have ..     ┃
  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛*/
        if let divide = message.bodyText
                    .range(of: "------------------ RFC822 Header Follows ------------------") {

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ gather the AOCE RFC822 header lines ..                                                           │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
            let aoceHeaders = String(message.bodyText[divide.upperBound...])
                .replacingOccurrences(of: "\t", with: " ")
                .replacingOccurrences(of: "\n ", with: "\n")
                .replacingOccurrences(of: "\n ", with: " ")
                .components(separatedBy: "\n").filter( { header in header.count > 0 } )

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ truncate the old body text at the AOCE RFC822 header line ..                                     │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
            message.bodyText = String(message.bodyText[..<divide.lowerBound])

            var aoceHeaderDict = [String:String]()
            aoceHeaders.forEach( { header in
                let splitHeader = header.split(separator: " ", maxSplits: 1)
                if splitHeader.count == 2 {
                    aoceHeaderDict.updateValue(String(splitHeader[1]), forKey: splitHeader[0].lowercased())
                }
            })

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ improve the "From:" and "Subject:" headers if possible ..                                        │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
            if message.headDict["from:"] == nil {
                message.headDict["from:"] = aoceHeaderDict["from:"] ?? "-- NO SENDER --"
                modified = true
            }

            if message.headDict["subject:"] == nil {
                message.headDict["subject:"] = aoceHeaderDict["subject:"] ?? "-- NO SUBJECT --"
                modified = true
            }

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ The oldest (last) AOCE "Received:" header should give a good date ..                             │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
            if let receivedAoceHeader = aoceHeaderDict["received:"],
               let receivedHeaderDateRange = receivedAoceHeader.range(of: "; ") {

                var aoceReceivedDate = String(receivedAoceHeader[receivedHeaderDateRange.upperBound...])

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ there might be another ";" before the date ..                                                    │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
                if let receivedHeaderDateRange2 = aoceReceivedDate.range(of: "; ") {
                    aoceReceivedDate = String(aoceReceivedDate[receivedHeaderDateRange2.upperBound...])
                }

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ .. and there's a better way to cull out various spurious pieces of text!                         │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
                aoceReceivedDate = aoceReceivedDate.lowercased()
                    .replacingOccurrences(of: " for ", with: "")
                    .replacingOccurrences(of: "aoce-list@forfar.uis.itd.umich.edu", with: "")
                    .replacingOccurrences(of: "aoce-list@umich.edu", with: "")
                    .replacingOccurrences(of: "gavin.eadie@umich.edu", with: "")
                    .replacingOccurrences(of: "gavin@umich.edu", with: "")
                    .replacingOccurrences(of: "gordon.leacock@umich.edu", with: "")
                    .replacingOccurrences(of: "gordonl@umich.edu", with: "")
                    .replacingOccurrences(of: "iposva@eworld.com", with: "")
                    .replacingOccurrences(of: "macsig@umich.edu", with: "")
                    .replacingOccurrences(of: "maser@umich.edu", with: "")
                    .replacingOccurrences(of: "mcberger@umich.edu", with: "")
                    .replacingOccurrences(of: "mike.alexander@umich.edu", with: "")
                    .replacingOccurrences(of: "mta@umich.edu", with: "")
                    .replacingOccurrences(of: "opendoc-interest@cil.org", with: "")
                    .replacingOccurrences(of: "opendoc-interest@cilabs.org", with: "")
                    .replacingOccurrences(of: "pdtted@umich.edu", with: "")
                    .replacingOccurrences(of: "pdtvkumar@mit.edu", with: "")
                    .replacingOccurrences(of: "psantini@umich.edu", with: "")
                    .replacingOccurrences(of: "showcase@umich.edu", with: "")
                    .replacingOccurrences(of: "ted.hanss@umich.edu", with: "")
                    .replacingOccurrences(of: "ted@umich.edu", with: "")

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ AOCE "Received:" should contain "93", "94" .. "98" to qualify for replacing the header "Date:"   │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
                if  aoceReceivedDate.contains("93") || aoceReceivedDate.contains("94") ||
                    aoceReceivedDate.contains("95") || aoceReceivedDate.contains("96") ||
                    aoceReceivedDate.contains("97") || aoceReceivedDate.contains("98") {
                    modified = true
                    message.headDict["date:"] = aoceReceivedDate
                }

            }

            if modified {
                try message.emit(file: fileIsAOCE_M)
            } else {
                try message.emit(file: fileIsAOCE_O)
            }

        } else {

/*┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
  ┃ the body does NOT contain "RFC822 Header" so the headers we have are the best we'll get ..       ┃
  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛*/
            if message.bodyText.count > 2 {

                if message.headDict["to:"] == nil {
                    message.headDict["to:"] = "Gavin Eadie <gavin+norecip@umich.edu"
                    try message.emit(file: fileNoRcvr)
                } else {
                    try message.emit(file: fileNormal)
                }
            }
        }
    }
} catch {
    print("no messages in file.")
}
