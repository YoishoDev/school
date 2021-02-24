//
//  AddCourseViewController.swift
//  RealmTestView
//
//  Created by mis on 16.02.21.
//
//  Copyright (c) [2021] [Michael Schmidt, michael.schmidt@app-making.de]
//  You can use it under the MIT License (You find it in file LICENSE)
//

import Cocoa
import RealmSwift

class AddCourseViewController: NSViewController {

    //  View-Elemente
    @IBOutlet weak var courseNameTextField: NSTextField!
    
    
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
     
        if courseNameTextField.stringValue.isEmpty {
            
            //  Hinweis
            let dialog = ModalOptionDialog(message: "Sie haben kein Fach eingegeben!",
                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                           dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
            dialog.showDialog()
            return
            
        }
        // Fach speichern
        do {
            
            //  Faecher laden
            let courseList = userRealm?.objects(Course.self)
            //  noch kein Fach gespeichert
            if !(courseList?.isEmpty ?? true) {
                
                //  pruefen, ob schon vorhanden
                //  ueber den Namen
                //
                for course in courseList! {
                    
                    if course.name.lowercased() == courseNameTextField.stringValue.lowercased() {
                        
                        let dialog = ModalOptionDialog(message: "Ein Fach mit diesem Namen existiert bereits!",
                                                       buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                                       dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
                        dialog.showDialog()
                        return
                    }
                    
                }
                
            }
            //  neues Objekt vom Typ Fach erstellen
            let course: Course = Course()
            if useSyncedRealm {
                
                // Ensure the realm was opened with sync.
                guard let syncConfiguration = userRealm?.configuration.syncConfiguration else {
                    
                    let dialog = ModalOptionDialog(message: "Cloud-Sync nicht korrekt initialisiert. Speichern nicht möglich!",
                                                   buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                                   dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
                    dialog.showDialog()
                    return
                    
                }
                course._partition = (syncConfiguration.partitionValue?.stringValue!)!
                
            }

            course.name = courseNameTextField.stringValue
            //  Transaktion beginnen
            userRealm?.beginWrite()
            //  Objekt speichern
            userRealm?.add(course)
            //  Transaktion abschliessen
            try userRealm?.commitWrite()
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
