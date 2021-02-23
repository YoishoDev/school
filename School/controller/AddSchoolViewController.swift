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
    private weak var delegate: RealmDelegate?
    
    //  Realm
    internal var userRealm: Realm?
    
    //  Initialsiierung der View
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
    }
    
    @IBAction func saveButtonClicked(_ sender: NSButton) {
        
        if schoolNameTextField.stringValue.isEmpty {
            
            //  Hinweis
            let dialog = ModalOptionDialog(message: "Sie haben keinen Namen eingegeben!",
                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                           dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
            dialog.showDialog()
            
        } else {
            
            // Schule speichern
            do {
                
                    // Ensure the realm was opened with sync.
                    guard let syncConfiguration = userRealm?.configuration.syncConfiguration else {
                        fatalError("Sync configuration not found! Realm not opened with sync?");
                    }

                    // Partition value must be of string type.
                    print(syncConfiguration.partitionValue!.stringValue!)

                    
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
                    school.name = schoolNameTextField.stringValue
                    //  Problem: Notify ueber Realm bevor Schule neu zugewiesen
                    //  Aktualisierung der Benutzereinstellungen
                    //  wir wissen hier noch nicht, ob das Hinzufuegen erfolgreich sein wird
                    let userSettings = UserDefaults.standard
                    userSettings.set(school.name, forKey: UserSettingsKeys.LAST_USED_SCHOOL_NAME)
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
            
    }
        
    @IBAction func cancelButtonClicked(_ sender: NSButton) {
    
        self.view.window?.close()
        
    }
      
}
