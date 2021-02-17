//
//  AddTeacherViewController.swift
//  RealmTestView
//
//  Created by mis on 16.02.21.
//
//  Copyright (c) [2021] [Michael Schmidt, michael.schmidt@app-making.de]
//  You can use it under the MIT License (You find it in file LICENSE)
//

import Cocoa
import RealmSwift

class AddTeacherViewController: NSViewController {

    //  View-Elemente
    @IBOutlet weak var teacherFirstNameTextField: NSTextField!
    @IBOutlet weak var teacherNameTextField: NSTextField!
    @IBOutlet weak var courseTableView: NSTableView!
    
    //  Liste der Faecher, Modell für Tabelle
    private var courseTableDataList = [Course]()
    //  Liste der ausgewaehlten Faecher
    private var inTableViewSelectedCourseList = [Course]()
    
    //  aktuelle Schule, aus MainViewController uebergeben
    //  Lehrer wird (automatisch) dieser Schule zugeordnet
    internal var actualSchool:School?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        courseTableView.delegate = self
        courseTableView.dataSource = self
        
        //  Kurse aus Realm laden
        do {
            
            // Realm initialisieren
            let realm = try Realm()
            //  Schulen laden
            let courseList = realm.objects(Course.self)
            for course in courseList {
                
                courseTableDataList.append(course)
                
            }
            
        } catch {
            
            let dialog = ModalOptionDialog(message: error.localizedDescription,
                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                           dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
            dialog.showDialog()
            
        }
        
        //  Tabelle mit Daten befuellen
        courseTableView.reloadData()
        //  keine Faecher vorausgewaehlt
        courseTableView.deselectAll(self)
        
    }
    
    @IBAction func saveButtonClicked(_ sender: NSButton) {
        
        if teacherNameTextField.stringValue.isEmpty || teacherFirstNameTextField.stringValue.isEmpty {
            
            //  Hinweis
            let dialog = ModalOptionDialog(message: "Sie haben keinen Namen bzw. Vornamen eingegeben!",
                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                           dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
            dialog.showDialog()
            
        } else {
            
            // Lehrer speichern, auch ohne ausgewaehlte Faecher moeglich
            do {
                
                // Realm initialisieren
                let realm = try Realm()
                //  Lehrer laden
                let teacherList = realm.objects(Teacher.self)
                //  es ist bereits mindestens 1 Lehrer gespeichert
                if !teacherList.isEmpty {
                    
                    //  pruefen, ob schon vorhanden
                    //  ueber Namen
                    //
                    for teacher in teacherList {
                        
                        if teacher.lastName.lowercased() == teacherNameTextField.stringValue.lowercased() &&
                            teacher.firstName.lowercased() == teacherFirstNameTextField.stringValue.lowercased() {
                            
                            let dialog = ModalOptionDialog(message: "Ein Lehrer mit dem Vornamen und Namen existiert bereits!",
                                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                                           dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
                            dialog.showDialog()
                            return
                        }
                        
                    }
                    
                }
                //  neues Objekt vom Typ Lehrer erstellen
                let teacher: Teacher = Teacher()
                teacher.lastName = teacherNameTextField.stringValue
                teacher.firstName = teacherFirstNameTextField.stringValue
                //  Schule zuordnen, da in MainView ausgewaehlt
                //  ueber LinkedObjects wird der Lehrer in der Schule automatisch eingetragen
                //  leider wird diese Aenderung scheinbar nicht "benachrichtigt"?
                //  https://github.com/realm/realm-cocoa/issues/7054
                if actualSchool != nil {
                    
                    teacher.schools.append(actualSchool!)
                    
                }
                
                //  evtl. zugeordnete Faecher speichern
                if !inTableViewSelectedCourseList.isEmpty {
                    
                    for course in inTableViewSelectedCourseList {
                        
                        teacher.courses.append(course)
                        
                    }
     
                }
                
                //  Transaktion beginnen
                realm.beginWrite()
                //  Objekt speichern
                realm.add(teacher)
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

//  Erweiterug des Controllers zur Interaktion mit der TableView (Daten)
extension AddTeacherViewController: NSTableViewDataSource {
    
    //  Anzahl der Zeilen ergibt sich aus der Anzahl der vorhandenen Daten
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return courseTableDataList.count
        
    }
    
    //  Objekt zur Darstellung in der jeweiligen Zeile der Tabellen-View
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
      
        let course = courseTableDataList[row]
        let cell = tableView.makeView(withIdentifier: (tableColumn!.identifier), owner: self) as? NSTableCellView
        cell?.textField?.stringValue = course.name

        return cell
        
    }
        
}

//  Erweiterug des Controllers zur Interaktion mit der TableView (Ereignisse)
extension AddTeacherViewController: NSTableViewDelegate {
    
    //  Nutzer waehlt Zeilen (Spalten) in der Tabelle aus
    func tableViewSelectionIsChanging(_ notification: Notification) {
            
        //  gewaehlte Objekte (Faecher) zwischenspeichern
        if !inTableViewSelectedCourseList.isEmpty {
            
            //  bisherige Auswahl loeschen
            inTableViewSelectedCourseList.removeAll()
            
        } else {
            
            //  gewaehlte Objekte speichern
            let rowIndexes = courseTableView.selectedRowIndexes
            for index in rowIndexes {
                
                inTableViewSelectedCourseList.append(courseTableDataList[index])
                
            }
            
        }
    
    }
 
}
