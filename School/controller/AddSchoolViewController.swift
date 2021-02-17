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
    
    //  MainViewController
    internal weak var mainViewController:MainViewController?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do view setup here.
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
                
                // Realm initialisieren
                let realm = try Realm()
                //  Schulen laden
                let schoolList = realm.objects(School.self)
                //  noch keine Schule gespeichert
                if !schoolList.isEmpty {
                    
                    //  pruefen, ob schon vorhanden
                    //  ueber Namen
                    //
                    for school in schoolList {
                        
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
                //  Transaktion beginnen
                realm.beginWrite()
                //  Objekt speichern
                realm.add(school)
                //  Transaktion abschliessen
                try realm.commitWrite()
                //  soeben erstellte Schule als aktuelle Schule setzen
                mainViewController?.actualSchool = school
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
