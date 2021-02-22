//
//  RealmSyncController.swift
//  School
//
//  Created by mis on 22.02.21.
//
//  Copyright (c) [2021] [Michael Schmidt, michael.schmidt@app-making.de]
//  You can use it under the MIT License (You find it in file LICENSE)
//

import Cocoa
import RealmSwift

class RealmSyncLoginViewController: NSViewController {

    //  View-Elemente
    @IBOutlet weak var realmSyncInfoLabel: NSTextFieldCell!
    @IBOutlet weak var emailAddressTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var anonLoginCheckBox: NSButton!
    
    //  App fuer Sync mit Cloud-DB
    internal var realmApp: App?
    internal var realmSyncConfiguration: Realm.Configuration?
    
    private func logInWithAPIKey() {
        
        let credentials = Credentials.userAPIKey("<api-key>")
        realmApp?.login(credentials: credentials) { (result) in
            switch result {
            case .failure(let error):
                print("Login failed: \(error.localizedDescription)")
            case .success(let user):
                print("Successfully logged in as user \(user)")
                // Now logged in, do something with user
                // Remember to dispatch to main if you are doing anything on the UI thread
            }
        }
        
    }
    
    private func logIn() {
        
        if anonLoginCheckBox.state == NSControl.StateValue.on {
            
            //  anonyme Anmeldung - Entwicklermodus
            let anonymousCredentials = Credentials.anonymous
            realmApp?.login(credentials: anonymousCredentials) { (result) in
                switch result {
                case .failure(let error):
                    let dialog = ModalOptionDialog(message: error.localizedDescription,
                                                   buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                                   dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
                    dialog.showDialog()
                    
                case .success(let user):
                    print("Successfully logged in as user \(user)")

                }
                
            }
            
        } else {
            
            //  Anmeldung mit E-Mail und Passwort
            if emailAddressTextField.stringValue.isEmpty && passwordTextField.stringValue.isEmpty {
                
                let dialog = ModalOptionDialog(message: "Bitte E-Mail-Adresse und Passwort eingeben!",
                                               buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                               dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
                dialog.showDialog()
                return
                
            }
            realmApp?.login(credentials: Credentials.emailPassword(
                                email: emailAddressTextField.stringValue,
                                password: passwordTextField.stringValue)) { (result) in
                switch result {
                case .failure(let error):
                    let dialog = ModalOptionDialog(message: error.localizedDescription,
                                                   buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                                   dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
                    dialog.showDialog()
                    
                case .success(let user):
                    print("Successfully logged in as user \(user)")
                    
                }
            }
            
        }
        let user = realmApp?.currentUser
        realmSyncConfiguration = user!.configuration(partitionValue: RealmAppSettings.PARTITION_KEY)
        
        Realm.asyncOpen(configuration: realmSyncConfiguration!) { result in
            switch result {
            case .failure(let error):
                let dialog = ModalOptionDialog(message: error.localizedDescription,
                                               buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                               dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
                dialog.showDialog()
                return
            case .success(let realm):
                print("Successfully opened realm: \(realm)")
           
            }
            
        }
        
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()

    }
    
    @IBAction func anonLogInCheckBoxClicked(_ sender: NSButton) {
        
        
        if anonLoginCheckBox.state == NSControl.StateValue.on {
            
            emailAddressTextField.isEditable = false
            passwordTextField.isEditable = false
            realmSyncInfoLabel.stringValue = "Nur zum Testen. Es werden keine Daten synchronisiert!"
            
        } else {
            
            emailAddressTextField.isEditable = true
            passwordTextField.isEditable = true
            realmSyncInfoLabel.stringValue = "Bitte Login-Daten eingeben."

        }
        
    }
    
    
    @IBAction func logInButtonClicked(_ sender: NSButton) {
        
        logIn()
        
    }
    
    
    @IBAction func cancelButtonClicked(_ sender: NSButton) {
        
        self.view.window?.close()
        
    }
    override func viewDidDisappear() {
        
        
    }
    
}
