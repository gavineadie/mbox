//
//  MboxOptions.swift
//
//
//  Created by Gavin Eadie on 1/19/20.
//

import Foundation
import TSCUtility

public class MboxOptions {

    init() {

        do {
            let parser = ArgumentParser(commandName: "mbox",
                                        usage: "mbox -gl=0000",
                                        overview: "The command is used for parsing mbox (mailbox) files.")

            let keepLable = parser.add(option: "--keep", shortName: "-k", kind: String.self,
                                       usage: "keep messages with this Google label",
                                       completion: ShellCompletion.none)

            let dropLable = parser.add(option: "--drop", shortName: "-d", kind: String.self,
                                       usage: "drop messages with this Google label",
                                       completion: ShellCompletion.none)

            let message = parser.add(positional: "message", kind: String.self, optional: true,
                                     usage: "This is what the message should say",
                                     completion: ShellCompletion.none)

            let names = parser.add(option: "--names", shortName: "-n", kind: [String].self,
                                   strategy: .oneByOne,
                                   usage: "Multiple names",
                                   completion: ShellCompletion.none)

            let arguments = try parser.parse(Array(CommandLine.arguments.dropFirst()))

            if let googleLabel = arguments.get(keepLable) { print("keep Google label: \(googleLabel)") }
            if let googleLabel = arguments.get(dropLable) { print("drop Google label: \(googleLabel)") }

            if let message = arguments.get(message) { print("Using message: \(message)") }

            if let multipleNames = arguments.get(names) { print("Using names: \(multipleNames)") }

        } catch ArgumentParserError.expectedValue(let value) {
            print("Missing value for argument \(value).")
        } catch ArgumentParserError.expectedArguments(let parser, let stringArray) {
            print("Parser: \(parser) Missing arguments: \(stringArray.joined()).")
        } catch {
            print(error.localizedDescription)
        }

    }
}
