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
    
    //  View-Elemente
    @IBOutlet weak var schoolNameComboBox: NSComboBox!
    @IBOutlet weak var countOfSchoolClassesLabel: NSTextField!
    @IBOutlet weak var countOfTeacherLabel: NSTextField!
    
    //  wird bei Aenderungen an der "Datenbank" aufgerufen
    fileprivate func updateView(_ notification: Realm.Notification, _ realm: Realm) {
        
        //  Auswahlbox neu befuellen
        let schoolList = realm.objects(School.self)
        if !schoolList.isEmpty {
           
            schoolNameComboBox.removeAllItems()
            
            var index:Int = 0
            for school in schoolList {

                //  Eintrag zur Auswahlbox hinzufuegen
                schoolNameComboBox.addItem(withObjectValue: school.name)
                //  aktuelle Schule setzen und selektieren
                if index == 0 {
                    if actualSchool?.name.uppercased() == school.name.uppercased() {
                        
                        actualSchool = school
                        schoolNameComboBox.selectItem(at: index)
                        index += 1
                        
                    }
                }
                
            }
        }
        //  Anzahl der zugeordneten Lehrer anzeigen
       countOfTeacherLabel.stringValue = String(actualSchool?.teacher.count ?? 0)
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
        
    }

}

//  Erweiterug des Controllers zur Interaktion mit der Auswahlbox
extension MainViewController: NSComboBoxDelegate {
    
    //  neue Schule (Name) in der Auswahlbox gewaehlt
    internal func comboBoxSelectionDidChange(_ notification: Notification) {
    
        if let school = schoolNameComboBox.objectValueOfSelectedItem as? School {
            
            //  aktuelle Schule setzen
            actualSchool = school
            //  View aktualisieren
            countOfTeacherLabel.stringValue = String(school.teacher.count)
            
        }
        
    }
    
}

