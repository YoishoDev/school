//
//  Global.swift
//  RealmTest
//
//  Created by mis on 15.02.21.
//
//  Copyright (c) [2021] [Michael Schmidt, michael.schmidt@app-making.de]
//  You can use it under the MIT License (You find it in file LICENSE)
//

import Foundation
import Cocoa

//  vorhandene Daten loeschen, Debug
let REMOVE_REALM_DATA = false

//  Set this to true if you have set up a MongoDB Realm app
//  with Realm Sync and anonymous authentication.
let USE_REALM_SYNC = false

//  Standard-Dialoge
public class ModalOptionDialog {
    
    public struct ButtonStyle {
        
        static let OK_OPTION: Int           = 1
        static let OK_CANCEL_OPTION: Int    = 2
        static let YES_NO_OPTION: Int       = 3
        
    }
    
    public struct DialogStyle {
        
        static let INFORMATION: Int    = 1
        static let WARNING: Int        = 2
        static let CRITICAL: Int       = 3
        
    }
    
    private let alert: NSAlert
    
    public init(message: String, buttonStyle: Int, dialogStyle: Int) {
        
        alert = NSAlert()
        alert.messageText = message
        
        switch buttonStyle {
        case ButtonStyle.OK_OPTION:
            alert.addButton(withTitle: "Ok")
        case ButtonStyle.OK_CANCEL_OPTION:
            alert.addButton(withTitle: "Ok")
            alert.addButton(withTitle: "Abbrechen")
        case ButtonStyle.YES_NO_OPTION:
            alert.addButton(withTitle: "Ja")
            alert.addButton(withTitle: "Nein")
        default:
            alert.addButton(withTitle: "Ok")
        }

        switch dialogStyle {
        case DialogStyle.INFORMATION:
            alert.icon = NSImage(named: "information")
            alert.alertStyle = .informational
        case DialogStyle.WARNING:
            alert.icon = NSImage(named: "warning")
            alert.alertStyle = .warning
        case DialogStyle.CRITICAL:
            alert.icon = NSImage(named: "critical")
            alert.alertStyle = .critical
        default:
            alert.icon = NSImage(named: "information")
            alert.alertStyle = .informational
        }
        
    }
    
    public func showDialog() {
        
        alert.runModal()
        
    }
    
}
