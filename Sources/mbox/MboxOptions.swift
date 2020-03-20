//
//  MboxOptions.swift
//
//
//  Created by Gavin Eadie on 1/19/20.
//

import Foundation
import TSCUtility

public struct MboxOptions {
    
    public var inputFile = "Desktop/MBOX/<<<<.mbox"
    public var outputFile = "Desktop/MBOX/>>>>.mbox"

    init() {

        do {
            let parser = ArgumentParser(commandName: "mbox",
                                        usage: "mbox [-keep=0000] [-drop=0000]",
                                        overview: "The command is used for parsing mbox (mailbox) files.")

            let keepLable = parser.add(option: "--keep", shortName: "-k", kind: String.self,
                                       usage: "keep messages with this Google label",
                                       completion: ShellCompletion.none)

            let dropLable = parser.add(option: "--drop", shortName: "-d", kind: String.self,
                                       usage: "drop messages with this Google label",
                                       completion: ShellCompletion.none)

            let mboxInput = parser.add(option: "--input", shortName: "-i", kind: String.self,
                                       usage: "read mbox information from this file",
                                       completion: ShellCompletion.none)

            let mboxOutput = parser.add(option: "--output", shortName: "-o", kind: String.self,
                                        usage: "write mbox information to this file",
                                        completion: ShellCompletion.none)

            let arguments = try parser.parse(Array(CommandLine.arguments.dropFirst()))

            if let googleLabel = arguments.get(keepLable) { print("keep Google label: \(googleLabel)") }
            if let googleLabel = arguments.get(dropLable) { print("drop Google label: \(googleLabel)") }

            if let inputFile = arguments.get(mboxInput) {
                print("read mbox file: \(inputFile)")
                self.inputFile = inputFile
            }

            if let outputFile = arguments.get(mboxOutput) {
                print("write mbox file: \(outputFile)")
                self.outputFile = outputFile
            }

        } catch ArgumentParserError.expectedValue(let value) {

            print("Missing value for argument \(value).")

        } catch ArgumentParserError.expectedArguments(let parser, let stringArray) {

            print("Parser: \(parser) Missing arguments: \(stringArray.joined()).")

        } catch {

            print(error.localizedDescription)

        }
    }
}
