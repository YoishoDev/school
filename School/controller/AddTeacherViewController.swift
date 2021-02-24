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
        
        courseTableView.delegate = self
        courseTableView.dataSource = self
        
        //  Kurse aus Realm laden
        let courseList = userRealm?.objects(Course.self)
        for course in courseList! {
            
            courseTableDataList.append(course)
            
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
            return
            
        }
        // Lehrer speichern, auch ohne ausgewaehlte Faecher moeglich
        do {
            
            //  Lehrer laden
            let teacherList = userRealm?.objects(Teacher.self)
            //  es ist bereits mindestens 1 Lehrer gespeichert
            if !(teacherList?.isEmpty ?? true) {
                
                //  pruefen, ob schon vorhanden
                //  ueber Namen
                //
                for teacher in teacherList! {
                    
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
            if useSyncedRealm {
                
                // Ensure the realm was opened with sync.
                guard let syncConfiguration = userRealm?.configuration.syncConfiguration else {
                    
                    let dialog = ModalOptionDialog(message: "Cloud-Sync nicht korrekt initialisiert. Speichern nicht möglich!",
                                                   buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                                   dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
                    dialog.showDialog()
                    return
                    
                }
                teacher._partition = (syncConfiguration.partitionValue?.stringValue!)!
                
            }
            
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
            userRealm?.beginWrite()
            //  Objekt speichern
            userRealm?.add(teacher)
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
