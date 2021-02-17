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
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do view setup here.
    }
    
    @IBAction func saveButtonClicked(_ sender: NSButton) {
     
        if courseNameTextField.stringValue.isEmpty {
            
            //  Hinweis
            let dialog = ModalOptionDialog(message: "Sie haben kein Fach eingegeben!",
                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                           dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
            dialog.showDialog()
            
        } else {
            
            // Fach speichern
            do {
                
                // Realm initialisieren
                let realm = try Realm()
                //  Faecher laden
                let courseList = realm.objects(Course.self)
                //  noch kein Fach gespeichert
                if !courseList.isEmpty {
                    
                    //  pruefen, ob schon vorhanden
                    //  ueber den Namen
                    //
                    for course in courseList {
                        
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
                course.name = courseNameTextField.stringValue
                //  Transaktion beginnen
                realm.beginWrite()
                //  Objekt speichern
                realm.add(course)
                //  Transaktion abschliessen
                try realm.commitWrite()
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
