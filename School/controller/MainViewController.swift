//
//  ViewController.swift
//  RealmTestView
//
//  Created by mis on 15.02.21.
//
//  Copyright (c) [2021] [Michael Schmidt, michael.schmidt@app-making.de]
//  You can use it under the MIT License (You find it in file LICENSE)
//

import Cocoa
import RealmSwift

class MainViewController: NSViewController {

    //  aktuelle Schule, fuer Uebergabe an andere Controller
    internal var actualSchool:School?
    
    //  Benachrichtigungen bei Aenderungen in der "Datenbank"
    private var realmNotificationToken: NotificationToken?
    private var realmSchoolCollectionNotificationToken: NotificationToken?
    private var objectNotificationToken: NotificationToken?
    
    //  View-Elemente
    @IBOutlet weak var schoolNameComboBox: NSComboBox!
    @IBOutlet weak var countOfSchoolClassesLabel: NSTextField!
    @IBOutlet weak var countOfTeacherLabel: NSTextField!
    
    //  Vbei Aenderungen an der "Datenbank" die View aktualisieren
    //  ueber LinkedObjects wird z.B. der Lehrer in der Schule automatisch eingetragen
    //  leider wird diese Aenderung scheinbar nicht "benachrichtigt"?
    //  https://github.com/realm/realm-cocoa/issues/7054
    private func updateView(_ notification: Realm.Notification, _ realm: Realm) {
        
        //  Auswahlbox neu befuellen
        let schoolList = realm.objects(School.self)
        if !schoolList.isEmpty {
           
            schoolNameComboBox.removeAllItems()
            
            var index:Int = 0
            for school in schoolList {

                //  Eintrag zur Auswahlbox hinzufuegen
                schoolNameComboBox.addItem(withObjectValue: school.name)
                //  aktuelle Schule setzen und selektieren
                if actualSchool?.name.uppercased() == school.name.uppercased() {
                        
                        schoolNameComboBox.selectItem(at: index)
                        
                }
                index += 1
            }
            //  Anzahl der zugeordneten Lehrer anzeigen
            countOfTeacherLabel.stringValue = String(actualSchool?.teacher.count ?? 0)
        }
        
    }
    
    //  wird bei Initalisieren der View aufgerufen
    override func viewDidLoad() {
        
        super.viewDidLoad()

        //  GUI mit (vorhandenen) Daten befuellen
        do {
            
            //  Realm initialisieren
            //  waehrend der Entwicklung bei Schema-Aenderungen alle bisherigen Daten loeschen
            let configuration = Realm.Configuration(deleteRealmIfMigrationNeeded: true)
            let realm = try Realm(configuration: configuration)
            //  fuer Tests
            if REMOVE_REALM_DATA {
                
                realm.beginWrite()
                //  alle Objekte loeschen
                realm.deleteAll()
                //  Transaktion abschliessen
                try realm.commitWrite()
                
                let dialog = ModalOptionDialog(message: "Alle Daten wurden gelöscht! Konfiguration prüfen!",
                                               buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                               dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
                dialog.showDialog()
                
            }
            //  Schulen laden und in Auswahlbox darstellen
            let schoolList = realm.objects(School.self)
            if !schoolList.isEmpty {
               
                var index:Int = 0
                for school in schoolList {

                    //  Eintrag zur Auswahlbox hinzufuegen
                    schoolNameComboBox.addItem(withObjectValue: school.name)
                    //  erste Schule aus Liste als aktuelle Schule setzen und selektieren
                    if index == 0 {
                        
                        actualSchool = school
                        objectNotificationToken = school.observe { change in
                            switch change {
                            case .change(let object, let properties):
                                for property in properties {
                                    print("Property '\(property.name)' of object \(object) changed to '\(property.newValue!)'")
                                }
                            case .error(let error):
                                let dialog = ModalOptionDialog(message: error.localizedDescription,
                                                               buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                                               dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
                                dialog.showDialog()
                            case .deleted:
                                return
                            }
                        }
                        schoolNameComboBox.selectItem(at: index)
                        index += 1
                        
                    }
                    
                }
            }
            //  Anzahl der zugeordneten Lehrer anzeigen
           countOfTeacherLabel.stringValue = String(actualSchool?.teacher.count ?? 0)
            
            //  Auswahlbox
            schoolNameComboBox.delegate = self
            
            //  Realm-Benachrichtigungen, hier komplett
            realmNotificationToken = realm.observe { notification, realm in
                
                self.updateView(notification, realm)
            }
            
        } catch {
            
            let dialog = ModalOptionDialog(message: error.localizedDescription,
                                           buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                           dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
            dialog.showDialog()
            
        }
    }
    
    //  wird vor Uebergabe an naechsten Controller aufgerufen
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        //  Ist das Ziel die AddSchoolView?
        if let destinationViewController = segue.destinationController as? AddSchoolViewController {
            
            //  Uebergabe des MainViewControllers an die naechste View (den Controller)
            destinationViewController.mainViewController = self
            return
            
        }
        
        //  Ist das Ziel die AddClassView?
        if let destinationViewController = segue.destinationController as? AddClassViewController {
            
            //  Uebergabe der aktuellen Schule an die naechste View (den Controller)
            destinationViewController.inViewSelectedSchool = actualSchool
            return
            
        }
        
        //  Ist das Ziel die AddTeacherView?
        if let destinationViewController = segue.destinationController as? AddTeacherViewController {
            
            //  Uebergabe der aktuellen Schule an die naechste View (den Controller)
            destinationViewController.actualSchool = actualSchool
            return

        }
        
    }
    
    override var representedObject: Any? {
        didSet {
            
            //  Update the view, if already loaded.
        }
    }

    override func viewDidDisappear() {
        
        realmNotificationToken?.invalidate()
        realmSchoolCollectionNotificationToken?.invalidate()
        objectNotificationToken?.invalidate()
        
    }

}

//  Erweiterug des Controllers zur Interaktion mit der Auswahlbox
extension MainViewController: NSComboBoxDelegate {
    
    //  neue Schule (Name) in der Auswahlbox gewaehlt
    internal func comboBoxSelectionDidChange(_ notification: Notification) {
    
        if let schoolName = schoolNameComboBox.objectValueOfSelectedItem as? String {
            
            //  aktuelle Schule aus Realm laden
            do {
                
                //  Realm initialisieren
                let realm = try Realm()
                //  Schulen laden
                let schoolList = realm.objects(School.self)
                //  nach Namen filtern
                let filterString = "name == '" + schoolName + "'"
                let filteredResultSet = schoolList.filter(filterString)
                if filteredResultSet.count == 1 {
                    
                    actualSchool = filteredResultSet[0]
                    //  View aktualisieren
                    countOfTeacherLabel.stringValue = String(actualSchool?.teacher.count ?? 0)
                    
                } else {
                    
                    let dialog = ModalOptionDialog(message: "Schuldaten konnten nicht geladen werden!",
                                                   buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                                   dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
                    dialog.showDialog()
                    
                }
                
            } catch {
                
                let dialog = ModalOptionDialog(message: error.localizedDescription,
                                               buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                               dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
                dialog.showDialog()
                
            }
            
        }
        
    }
    
}

