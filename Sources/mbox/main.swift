//
//  main.swift
//  mboxFileParser
//
//  Created by Gavin Eadie on 6/6/18.
//  Copyright © 2018 Gavin Eadie. All rights reserved.
//

import Foundation
import Files

// TODO: gather GMAIL labels (multiple occurences) .. drop "0000" keep others (like "1998")
// TODO: gather "Received:" (multiple occurences)

let homeDirectory = Folder.home

let options = MboxOptions()

/// an MBOX file contains concatenated RFC822 mail messages.  Each starts with a line "From " and
/// ends with a newline .. our first job is to split these out so they can be examined individually.

typealias oneMessage = [String]

print("      start: \(Date())")

//let fileNoSndr = try homeDirectory.createFileIfNeeded(at: "Desktop/nosend.mbox")
//let fileIsAOCE_M = try homeDirectory.createFileIfNeeded(at: "Desktop/isaoce-modified.mbox")
//let fileIsAOCE_O = try homeDirectory.createFileIfNeeded(at: "Desktop/isaoce-original.mbox")
//let fileNoRcvr = try homeDirectory.createFileIfNeeded(at: "Desktop/norcvr.mbox")
//let fileIsRich = try homeDirectory.createFileIfNeeded(at: "Desktop/isrich.mbox")

let fileToRead = try homeDirectory.file(at: "Desktop/0000.mbox")
let fileNormal = try homeDirectory.createFileIfNeeded(at: "Desktop/normal.mbox")

print("mbox mapped: \(Date())")

do {
    let mboxRecords = try fileToRead.readAsString(encodedAs: .utf8)

    print("mbox String: \(Date())")

    let messageArray = (messageSeparator + mboxRecords).components(separatedBy: messageSeparator)

    print(" mbox split: \(Date()) .. \(messageArray.count) messages in file.")

    for message in messageArray {                                           // ~135 seconds
        var modified = false

        if var newMessage = Message(message) {

// TODO: watch for "<extract>"

//            if newMessage.bodyText.contains("<x-flowed>") {
//                newMessage.bodyText = newMessage.bodyText
//                    .replacingOccurrences(of: "<x-flowed>", with: "")    // TODO: what does "x-flowed" actually imply?
//                    .replacingOccurrences(of: "</x-flowed>", with: "")
////                    .replacingOccurrences(of: "<#T##StringProtocol#>", with: "")
////                    .replacingOccurrences(of: "<#T##StringProtocol#>", with: "")
//                try newMessage.print(file: fileIsRich)
//                continue
//            }

/*┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
  ┃ the body contains "RFC822 Header" so we can use these AOCE headers to refine what we have ..     ┃
  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛*/
            if let divide = newMessage.bodyText
                        .range(of: "------------------ RFC822 Header Follows ------------------") {

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ gather the AOCE RFC822 header lines ..                                                           │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
                let aoceHeaders = String(newMessage.bodyText[divide.upperBound...])
                    .replacingOccurrences(of: "\t", with: " ")
                    .replacingOccurrences(of: "\n ", with: "\n")
                    .replacingOccurrences(of: "\n ", with: " ")
                    .components(separatedBy: "\n").filter( { header in header.count > 0 } )

/*┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ truncate the old body text at the AOCE RFC822 header line ..                                     │
  └──────────────────────────────────────────────────────────────────────────────────────────────────┘*/
                newMessage.bodyText = String(newMessage.bodyText[..<divide.lowerBound])

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
                if newMessage.headDict["from:"] == nil {
                    newMessage.headDict["from:"] = aoceHeaderDict["from:"] ?? "-- NO SENDER --"
                    modified = true
                }

                if newMessage.headDict["subject:"] == nil {
                    newMessage.headDict["subject:"] = aoceHeaderDict["subject:"] ?? "-- NO SUBJECT --"
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
                        newMessage.headDict["date:"] = aoceReceivedDate
                    }

                }

//                if modified {
//                    try newMessage.print(file: fileIsAOCE_M)
//                } else {
//                    try newMessage.print(file: fileIsAOCE_O)
//                }

            }

/*┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
  ┃ the body does NOT contain "RFC822 Header" so the headers we have are the best we'll get ..       ┃
  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛*/
            else {
                if newMessage.bodyText.count > 2 {

//                    if newMessage.headDict["to:"] == nil {
//                        newMessage.headDict["to:"] = "Gavin Eadie <gavin+norecip@umich.edu"
//                        try newMessage.print(file: fileNoRcvr)
//                    } else {
//                        try newMessage.print(file: fileNormal)
//                    }
                }
            }
        }
    }

} catch {
    print("no messages in file.")
}
