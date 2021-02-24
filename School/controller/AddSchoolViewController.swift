//
//  AddSchoolViewController.swift
//  RealmTestView
//
//  Created by mis on 16.02.21.
//
//  Copyright (c) [2021] [Michael Schmidt, michael.schmidt@app-making.de]
//  You can use it under the MIT License (You find it in file LICENSE)
//

import Cocoa
import RealmSwift

class AddSchoolViewController: NSViewController {

    //  View-Elemente
    @IBOutlet weak var schoolNameTextField: NSTextField!
    
    //  Delegate - fuer Uebergabe des Realm
    internal weak var delegate: RealmDelegate?
    
    //  Realm
    internal var userRealm: Realm?
    
    //  Sync aktiviert?
    var useSyncedRealm: Bool = false
    
    //  wird nach dem Initialisieren der View aufgerufen
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //  Cloud-Sync aktiviert?
        if RealmAppSettings.USE_REALM_SYNC {
        
            //  Nutzer hat es auch aktiviert?
            if UserSettings.keyExists(UserSettings.USE_REALM_SYNC) {
                
                let userSettings = UserDefaults.standard
                if userSettings.bool(forKey: UserSettings.USE_REALM_SYNC) {
                    
                    useSyncedRealm = true
                    
                }
                    
            }
            
        }
        
    }
    
    @IBAction func saveButtonClicked(_ sender: NSButton) {
        
        if schoolNameTextField.stringValue.isEmpty {
            
            //  Hinweis
            let dialog = ModalOptionDialog(message: "Sie haben keinen Namen eingegeben!",
                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                           dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
            dialog.showDialog()
            return
            
        }
        // Schule speichern
        do {
                
                //  Schulen laden
                let schoolList = userRealm?.objects(School.self)
                //  noch keine Schule gespeichert
                if !(schoolList?.isEmpty ?? true) {
                    
                    //  pruefen, ob schon vorhanden
                    //  ueber Namen
                    for school in schoolList! {
                        
                        if school.name.lowercased() == schoolNameTextField.stringValue.lowercased() {
                            
                            let dialog = ModalOptionDialog(message: "Eine Schule mit diesem Namen existiert bereits!",
                                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                                           dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
                            dialog.showDialog()
                            return
                        }
                        
                    }
                    
                }
            
                //  neues Objekt vom Typ Schule erstellen
                let school: School = School()
                if useSyncedRealm {
                    
                    // Ensure the realm was opened with sync.
                    guard let syncConfiguration = userRealm?.configuration.syncConfiguration else {
                        
                        let dialog = ModalOptionDialog(message: "Cloud-Sync nicht korrekt initialisiert. Speichern nicht möglich!",
                                                       buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                                       dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
                        dialog.showDialog()
                        return
                        
                    }
                    school._partition = (syncConfiguration.partitionValue?.stringValue!)!
                    
                }

                school.name = schoolNameTextField.stringValue
                //  Problem: Notify ueber Realm bevor Schule neu zugewiesen
                //  Aktualisierung der Benutzereinstellungen
                //  wir wissen hier noch nicht, ob das Hinzufuegen erfolgreich sein wird
                let userSettings = UserDefaults.standard
                userSettings.set(school.name, forKey: UserSettings.LAST_USED_SCHOOL_NAME)
                //  Transaktion beginnen
                userRealm?.beginWrite()
                //  Objekt speichern
                userRealm?.add(school)
                //  Transaktion abschliessen
                try userRealm?.commitWrite()
                //  MainView "benachrichtigen"
                //  neue Schule als aktuelle Schule setzen
                delegate?.schoolWasAdded(school)
                //  Fenster schliessen
                self.view.window?.close()
                
            } catch {
            
            let dialog = ModalOptionDialog(message: error.localizedDescription,
                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                           dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
            dialog.showDialog()
            
        }
            
    }
        
    @IBAction func cancelButtonClicked(_ sender: NSButton) {
    
        self.view.window?.close()
        
    }
      
}
