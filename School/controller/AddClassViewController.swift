//
//  AddClassViewController.swift
//  RealmTestView
//
//  Created by mis on 16.02.21.
//
//  Copyright (c) [2021] [Michael Schmidt, michael.schmidt@app-making.de]
//  You can use it under the MIT License (You find it in file LICENSE)
//

import Cocoa
import RealmSwift

class AddClassViewController: NSViewController {

    //  aktuelle Schule, aus MainViewController uebergeben
    internal var inViewSelectedSchool:School?
    
    //  View-Elemente
    @IBOutlet weak var classNameTextField: NSTextField!
    @IBOutlet weak var classTeacherComboBox: NSComboBox!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //  Liste von (moeglichen) Klassenlehrern laden
        //  muessen an der gleichen Schule auch unterrichten
        if let teacherList = inViewSelectedSchool?.teacher {
        
            if !teacherList.isEmpty {
            
                for teacher in teacherList {
                        
                    classTeacherComboBox.addItem(withObjectValue: teacher.firstName + " " + teacher.lastName)
                        
                }
                    
                classTeacherComboBox.selectItem(at: 0)
            }
            
        }
        
    }
    
    @IBAction func saveButtonClicked(_ sender: NSButton) {
        
        if classNameTextField.stringValue.isEmpty {
            
            //  Hinweis
            let dialog = ModalOptionDialog(message: "Sie haben keinen Namen eingegeben!",
                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                           dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
            dialog.showDialog()
            
        } else {
            
            // Klasse der Schule laden
            if let schoolClasses = inViewSelectedSchool?.schoolClasses {
                
                //  pruefen, ob schon die Klasse schon an der Schule vorhanden ist
                //  ueber Namen
                if !schoolClasses.isEmpty {
                    
                    //  Keine Klassen zugeordnet
                    //  Klasse speichern, Name kann an anderer Schule existieren
                    //  bekommt als Objekt aber eine eindeutige ID
                    
                    do {
                        
                        //  Realm initialisieren
                        let realm = try Realm()
                        //  neues Objket vom Typ Klasse erstellen
                        let schoolClass: SchoolClass = SchoolClass()
                        schoolClass.name = classNameTextField.stringValue
                        //  Transaktion beginnen
                        realm.beginWrite()
                        //  Klasse speichern
                        realm.add(schoolClass)
                        //  Klasse der Schule hinzufuegen, ueber definierte Relation in Realm
                        inViewSelectedSchool?.schoolClasses.append(schoolClass)
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
            
        }
        
    }
    
    @IBAction func cancelButtonClicked(_ sender: NSButton) {
        
        self.view.window?.close()
        
    }
}
