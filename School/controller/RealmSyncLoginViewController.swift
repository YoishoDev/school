//
//  RealmSyncLoginViewController.swift
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
    @IBOutlet weak var loginButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var anonLoginCheckBox: NSButton!
    @IBOutlet weak var saveLoginCheckBox: NSButton!
    
    //  Aktivitaetenanzeige
    private let progressIndicator = NSProgressIndicator()
    
    //  Delegate - fuer Uebergabe des Realm
    internal weak var delegate: RealmDelegate?
    
    //  Realm-App - Zugriff auf die Cloud-DB
    private let realmApp = App(id: RealmAppSettings.REALM_APP_ID)
    
    //  Benutzereinstellungen
    internal let userSettings = UserDefaults.standard
    
    // Turn on or off the activity indicator.
    func setLoading(_ loading: Bool) {
        
        if loading {
            
            progressIndicator.startAnimation(self)
            realmSyncInfoLabel.stringValue = ""
            
        } else {
            
            progressIndicator.stopAnimation(self)
            
        }
        
        emailAddressTextField.isEnabled = !loading
        passwordTextField.isEnabled = !loading
        loginButton.isEnabled = !loading
        cancelButton.isEnabled = !loading
    }
    
    //  neuen Nutzer registrieren
    private func registerNewUser() {
        
        setLoading(true);
        realmApp.emailPasswordAuth.registerUser(email: emailAddressTextField.stringValue,
                                                password: passwordTextField.stringValue,
                                                completion: { [weak self](error) in
            
            // Completion handlers are not necessarily called on the UI thread.
            // This call to DispatchQueue.main.sync ensures that any changes to the UI,
            // namely disabling the loading indicator and navigating to the next page,
            // are handled on the UI thread:
            DispatchQueue.main.sync {
                
                self!.setLoading(false);
                guard error == nil else {
                    print("Signup failed: \(error!)")
                    self!.realmSyncInfoLabel.stringValue = "Signup failed: \(error!.localizedDescription)"
                    return
                }
                print("Signup successful!")

                // Registering just registers. Now we need to sign in, but we can reuse the existing email and password.
                self!.realmSyncInfoLabel.stringValue = "Signup successful! Signing in..."
                self!.logInWithEmailAndPassword()
            }
        })
    }
    
    //  Login mit API-Key, dieser muss gespeichert werden!
    //  ansonsten ist kein Login mehr moeglich
    private func logInWithAPIKey() {
        
        let credentials = Credentials.userAPIKey("<api-key>")
        realmApp.login(credentials: credentials) { (result) in
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
    
    //  anaonyme Anmeldung
    private func logInAsAnonymous() {
        
        //  anonyme Anmeldung - Entwicklermodus
        let anonymousCredentials = Credentials.anonymous
        realmApp.login(credentials: anonymousCredentials) { (result) in
            switch result {
            case .failure(let error):
                let dialog = ModalOptionDialog(message: error.localizedDescription,
                                               buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                               dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
                dialog.showDialog()
                
            case .success(let user):
                self.realmSyncInfoLabel.stringValue = "Login succeeded!"
                // Load again while we open the realm.
                self.setLoading(true);
                // Partionierung nach Nutzer - jeder Nutzer sieht nur seine Daten
                var configuration = user.configuration(partitionValue: "user=\(user.id)")
                // Only allow User objects in this partition. - ??? Alles laden?
                configuration.objectTypes = [School.self, SchoolClass.self, Course.self, Teacher.self, Student.self]
                // Open the realm asynchronously so that it downloads the remote copy before
                // opening the local copy.
                Realm.asyncOpen(configuration: configuration) { [weak self](result) in
                    DispatchQueue.main.async {
                        
                        self!.setLoading(false);
                        switch result {
                        case .failure(let error):
                            let dialog = ModalOptionDialog(message: error.localizedDescription,
                                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                                           dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
                            dialog.showDialog()
                            return
                        case .success(let userRealm):
                            //  Main benachrichtigen und Cloud-Realm uebergeben
                            self?.delegate?.cloudRealmWasInit(userRealm)
                            //  modal schliessen, weiter in MainView
                            self?.view.window?.close()
                        }
                        
                    }
                    
                }
                
            }
            
        }
                
    }
    
    private func logInWithEmailAndPassword() {
       
        realmSyncInfoLabel.stringValue = "Log in as user: \(emailAddressTextField.stringValue)"
        setLoading(true);

        realmApp.login(credentials: Credentials.emailPassword(email: emailAddressTextField.stringValue,
                                                              password: "ificant12OPQ")) { [weak self](result) in
            
            // Completion handlers are not necessarily called on the UI thread.
            // This call to DispatchQueue.main.sync ensures that any changes to the UI,
            // namely disabling the loading indicator and navigating to the next page,
            // are handled on the UI thread:
            DispatchQueue.main.async {
               
                self!.setLoading(false);
                switch result {
                case .failure(let error):
                    // Auth error: user already exists? Try logging in as that user.
                    print("Login failed: \(error)");
                    self!.realmSyncInfoLabel.stringValue = "Login failed: \(error.localizedDescription)"
                    return
                case .success(let user):
                    self!.realmSyncInfoLabel.stringValue = "Login succeeded!"
                    // Load again while we open the realm.
                    self!.setLoading(true);
                    // Partionierung nach Nutzer - jeder Nutzer sieht nur seine Daten
                    var configuration = user.configuration(partitionValue: "user=\(user.id)")
                    // Only allow User objects in this partition. - ??? Alles laden?
                    configuration.objectTypes = [School.self, SchoolClass.self, Course.self, Teacher.self, Student.self]
                    // Open the realm asynchronously so that it downloads the remote copy before
                    // opening the local copy.
                    Realm.asyncOpen(configuration: configuration) { [weak self](result) in
                        DispatchQueue.main.async {
                            
                            self!.setLoading(false);
                            switch result {
                            case .failure(let error):
                                let dialog = ModalOptionDialog(message: error.localizedDescription,
                                                               buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                                               dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
                                dialog.showDialog()
                                return
                            case .success(let userRealm):
                                //  Main benachrichtigen und Cloud-Realm uebergeben
                                self?.delegate?.cloudRealmWasInit(userRealm)
                                //  modal schliessen, weiter in MainView
                                self?.view.window?.close()
                            }
                        }
                    }
                }
            }
        };
        
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //  Login gespeichert? Felder vorbelegen
        if UserSettings.keyExists(UserSettings.SAVE_LOGIN) {
            if userSettings.bool(forKey: UserSettings.SAVE_LOGIN) {
                
                if let lastUsedEmail = userSettings.string(forKey: UserSettings.LAST_USED_EMAIL) {
                    
                    saveLoginCheckBox.state = NSControl.StateValue.on
                    //  Problem beim Login
                    //emailAddressTextField.stringValue = lastUsedEmail
                }
                
            }
            
        }
        
        //  Aktivitaetenanzeige
        progressIndicator.style = NSProgressIndicator.Style.spinning
        progressIndicator.usesThreadedAnimation = true
        self.view.addSubview(progressIndicator)

    }
    
    @IBAction func anonLogInCheckBoxClicked(_ sender: NSButton) {
        
        
        if anonLoginCheckBox.state == NSControl.StateValue.on {
            
            emailAddressTextField.isEditable = false
            passwordTextField.isEditable = false
            realmSyncInfoLabel.stringValue = "Nur zum Testen. Es werden keine Daten synchronisiert!"
            
        } else {
            
            emailAddressTextField.isEditable = true
            passwordTextField.isEditable = true
            if emailAddressTextField.stringValue.isEmpty || passwordTextField.stringValue.isEmpty {
                
            realmSyncInfoLabel.stringValue = "Bitte Login-Daten eingeben."
                
            }

        }
        
    }
    
    
    @IBAction func logInButtonClicked(_ sender: NSButton) {
        
        if anonLoginCheckBox.state == NSControl.StateValue.off {
        
            //  Anmeldung mit E-Mail und Passwort
            //  Daten eingegeben?
            if emailAddressTextField.stringValue.isEmpty && passwordTextField.stringValue.isEmpty {
                
                let dialog = ModalOptionDialog(message: "Bitte E-Mail-Adresse und Passwort eingeben!",
                                               buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                               dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
                dialog.showDialog()
                return
                
            } else {
                
                //  Login-Daten speichern?
                if saveLoginCheckBox.state == NSControl.StateValue.on {
                    
                    userSettings.setValue(true, forKey: UserSettings.SAVE_LOGIN)
                    userSettings.setValue(emailAddressTextField.stringValue, forKey: UserSettings.LAST_USED_EMAIL)
                    
                }
                
            }
            
            logInWithEmailAndPassword()
            
        } 
        else {
            
            logInAsAnonymous()
            
        }
    }
    
    
    @IBAction func cancelButtonClicked(_ sender: NSButton) {
        
        self.view.window?.close()
        
    }
    override func viewDidDisappear() {
        
        
    }
    
}
