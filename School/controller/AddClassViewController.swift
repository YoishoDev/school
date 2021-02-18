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
    internal var actualSchool:School?
    
    //  Liste der moeglichen (Klassen-) Lehrer
    internal var actualSchoolTeacherList = [Teacher]()
    
    //  View-Elemente
    @IBOutlet weak var classNameTextField: NSTextField!
    @IBOutlet weak var classTeacherComboBox: NSComboBox!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //  Liste von (moeglichen) Klassenlehrern laden
        //  muessen an der gleichen Schule auch unterrichten
        if let teacherList = actualSchool?.teacher {
        
            if !teacherList.isEmpty {
            
                for teacher in teacherList {
                    
                    //  Auswahlbox befuellen, Annahme: Index Box und Array ist gleich
                    actualSchoolTeacherList.append(teacher)
                    classTeacherComboBox.addItem(withObjectValue: teacher.firstName + " " + teacher.lastName)
                    
                }

            }
            
        }
        
    }
    
    @IBAction func saveButtonClicked(_ sender: NSButton) {
        
        if classTeacherComboBox.indexOfSelectedItem < 0 {
            
            //  Hinweis
            let dialog = ModalOptionDialog(message: "Sie haben keinen Klassenlehrer ausgewählt!",
                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                           dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
            dialog.showDialog()
            return
            
        }
        
        if classNameTextField.stringValue.isEmpty {
            
            //  Hinweis
            let dialog = ModalOptionDialog(message: "Sie haben keinen Namen eingegeben!",
                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                           dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
            dialog.showDialog()
            
        } else {
            
            // Klasse der Schule laden
            if let schoolClassList = actualSchool?.schoolClasses {
                
                if !schoolClassList.isEmpty {
                    
                    //  pruefen, ob schon vorhanden
                    //  ueber Namen
                    //
                    for schoolClass in schoolClassList {
                        
                        if schoolClass.name.lowercased() == classNameTextField.stringValue.lowercased() {
                            
                            let dialog = ModalOptionDialog(message: "Eine Klasse mit diesem Namen existiert bereits an der Schule!",
                                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                                           dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
                            dialog.showDialog()
                            return
                        }
                        
                    }
                    
                }
                //  Klasse speichern
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
                        //  Klasse der Schule zuordnen
                        actualSchool?.schoolClasses.append(schoolClass)
                        //  Klassenlehrer zuordnen
                        schoolClass.classTeacher = actualSchoolTeacherList[classTeacherComboBox.indexOfSelectedItem]
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
    
    @IBAction func cancelButtonClicked(_ sender: NSButton) {
        
        self.view.window?.close()
        
    }
}
