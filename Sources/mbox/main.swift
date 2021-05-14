//
//  main.swift
//  mbox
//
//  Created by Gavin Eadie on 5/13/21.
//

import Foundation
import ArgumentParser
import Files

struct Mbox: ParsableCommand {
    
    public var inputFile = "Desktop/MBOX/<<<<.mbox"
    public var outputFile = "Desktop/MBOX/>>>>.mbox"

//  @Argument(help: "String to count the characters of") var string: String
    
    @Option(name: .shortAndLong, help: "the directory containg 'mbox' files.")
    var base: String?

    @Option(name: .shortAndLong, help: "keep messages with this Google label.")
    var keep: String?

    @Option(name: .shortAndLong, help: "drop messages with this Google label.")
    var drop: String?

    @Option(name: .shortAndLong, help: "read mbox information from this file.")
    var input: String?

    @Option(name: .shortAndLong, help: "write mbox information to this file.")
    var exput: String?
    
    func run() throws {
        let baseDir = base ?? "~/Desktop/MBOXS"         // ### deliberate failure ###

        guard let baseDirectory = try? Folder(path: baseDir) else {
            print("   base directory: '\(baseDir)' doesn't exist .. exiting.")
            return
        }
        
        print("   base directory: '\(baseDirectory)'.")

/// an MBOX file contains concatenated RFC822 mail messages.  Each starts with a line "From " and
/// ends with a newline .. our first job is to split these out so they can be examined individually.

        typealias oneMessage = [String]

        print("            start: \(Date())")

        let fileNoSndr = try baseDirectory.createFileIfNeeded(at: "MBOX/nosend.mbox")
        let fileAOCE_M = try baseDirectory.createFileIfNeeded(at: "MBOX/isaoce-modified.mbox")
        let fileAOCE_O = try baseDirectory.createFileIfNeeded(at: "MBOX/isaoce-original.mbox")
        let fileNoRcvr = try baseDirectory.createFileIfNeeded(at: "MBOX/norcvr.mbox")
        let fileIsRich = try baseDirectory.createFileIfNeeded(at: "MBOX/isrich.mbox")

        let keepLabel = keep ?? "KEEP"
        print("     keep 'label': \(keepLabel)")

        let dropLabel = drop ?? "DROP"
        print("     drop 'label': \(dropLabel)")

        let inpFile = input ?? "<<<<.mbox"
        print("       input mbox: \(inpFile)")

        let outFile = exput ?? ">>>>.mbox"
        print("       input mbox: \(outFile)")
    }
}

Mbox.main()
