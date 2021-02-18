//
//  AddStudentViewController.swift
//  RealmTestView
//
//  Created by mis on 16.02.21.
//
//  Copyright (c) [2021] [Michael Schmidt, michael.schmidt@app-making.de]
//  You can use it under the MIT License (You find it in file LICENSE)
//

import Cocoa
import RealmSwift

class AddStudentViewController: NSViewController {

    //  View-Elemente
    @IBOutlet weak var studentFirstNameTextField: NSTextField!
    @IBOutlet weak var studentLastNameTextField: NSTextField!
    @IBOutlet weak var schoolClassComboBox: NSComboBox!
    
    //  aktuelle Schule, aus MainViewController uebergeben
    internal var actualSchool:School?
    //  alle Klassen der Schule
    internal var schoolClassOfActualSchool = [SchoolClass]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //  Liste von (moeglichen) Klassen laden
        //  muessen der gleichen Schule zugeordnet sein
        if let schoolClassList = actualSchool?.schoolClasses {
            
            if !schoolClassList.isEmpty {
            
                for schoolClass in schoolClassList {
                        
                    schoolClassComboBox.addItem(withObjectValue: schoolClass.name)
                    schoolClassOfActualSchool.append(schoolClass)
                        
                }
                
            }
            
        }
    }
    
    
    @IBAction func saveButtonClicked(_ sender: NSButton) {
        
        if schoolClassComboBox.indexOfSelectedItem < 0 {
            
            //  Hinweis
            let dialog = ModalOptionDialog(message: "Sie haben keine Klasse ausgewählt!",
                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                           dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
            dialog.showDialog()
            return
            
        }
        
        if studentFirstNameTextField.stringValue.isEmpty || studentLastNameTextField.stringValue.isEmpty {
            
            //  Hinweis
            let dialog = ModalOptionDialog(message: "Sie haben keinen Namen bzw. Vornamen eingegeben!",
                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                           dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
            dialog.showDialog()
            
        } else {
            
            // Schüler speichern
            do {
                
                //  Realm initialisieren
                let realm = try Realm()
                //  in der ausgewaehlten Klasse nach dem neu anzulegenden Schueler suchen
                //  ein Schueler mit gleichem Namen darf in einer anderen Klasse sein
                //  evtl. koennte man das ueber eine Realm-Query loesen?
                for schoolClass in schoolClassOfActualSchool {
                    
                    if !schoolClass.student.isEmpty {

                        //  in Auswahlbox gewaehlte Klasse entspricht der Klasse aus der Liste
                        if schoolClass.name.uppercased() == schoolClassComboBox.stringValue.uppercased() {
                            for student in schoolClass.student {
                                
                                if student.firstName.uppercased() == studentFirstNameTextField.stringValue.uppercased() &&
                                    student.lastName.uppercased() == studentLastNameTextField.stringValue.uppercased() {
                                
                                        let dialog = ModalOptionDialog(message: "Ein Schüler mit dem Vornamen und Namen existiert bereits (in dieser Klasse)!",
                                                                       buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                                                       dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
                                        dialog.showDialog()
                                        return
                                    
                                }
                            }
                            
                        }
                        
                    }
                    
                }
                //  neues Objekt vom Typ Schueler erstellen
                let student: Student = Student()
                student.firstName = studentFirstNameTextField.stringValue
                student.lastName = studentLastNameTextField.stringValue
                //  Klasse zuordnen
                let schoolClass = schoolClassOfActualSchool[schoolClassComboBox.indexOfSelectedItem]
                student.schoolClass = schoolClass
                //  Transaktion beginnen
                realm.beginWrite()
                //  Schueler speichern
                realm.add(student)
                //  Schueler der Klasse hinzufuegen
                schoolClass.student.append(student)
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

/*
extension AddStudentViewController: NSComboBoxDataSource {
    
    //  Anzahl der benoetigten Eintrage (Datensaetze)
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        
        return schoolClassOfActualSchool.count
        
    }
    
    //  ausgewaehltes Objekt zurueckgeben
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        
        return schoolClassOfActualSchool[index]
    }
    
}*/
