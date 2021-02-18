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
    
    //  zuletzt bearbeitete Schule speichern
    internal let userSettings = UserDefaults.standard
    
    //  Benachrichtigungen bei Aenderungen in der "Datenbank"
    private var realmNotificationToken: NotificationToken?
    
    //  View-Elemente
    @IBOutlet weak var schoolNameComboBox: NSComboBox!
    @IBOutlet weak var countOfSchoolClassesLabel: NSTextField!
    @IBOutlet weak var countOfCourseLabel: NSTextField!
    @IBOutlet weak var countOfTeacherLabel: NSTextField!
    @IBOutlet weak var countOfStudentsLabel: NSTextField!
    
    @IBOutlet weak var firstStepLabel: NSTextField!
    @IBOutlet weak var secondStepLabel: NSTextField!
    @IBOutlet weak var thirdStepLabel: NSTextField!
    @IBOutlet weak var fourthStepLabel: NSTextField!
    @IBOutlet weak var fivedStepLabel: NSTextField!
    
    @IBOutlet weak var addCourseButton: NSButton!
    @IBOutlet weak var addTeacherButton: NSButton!
    @IBOutlet weak var addSchoolClassButton: NSButton!
    @IBOutlet weak var addStudentButton: NSButton!
    
    //  Label fuer die ersten Schritte
    private var isFirstStepCompleted: Bool = false
    private var firstStepLabelList = [NSTextField]()
    private var firstStepButtonList = [NSButton]()
    
    //  bei Aenderungen an der "Datenbank" die View aktualisieren
    //  ueber LinkedObjects wird z.B. der Lehrer in der Schule automatisch eingetragen
    //  leider wird diese Aenderung scheinbar nicht "benachrichtigt"?
    //  https://github.com/realm/realm-cocoa/issues/7054
    private func updateView(_ notification: Realm.Notification, _ realm: Realm) {
        
        //  Auswahlbox neu befuellen
        let schoolList = realm.objects(School.self)
        if !schoolList.isEmpty {
           
            //  es wurde eine Schule angelegt -> erste Schritte Stufe 2
            if !isFirstStepCompleted {
                
                userSettings.set(2, forKey: UserSettingsKeys.FIRST_RUN_STEP)
                updateFirstStepLabel(firstStepValue: 2)
                
            }

            schoolNameComboBox.removeAllItems()
            
            var index:Int = 0
            for school in schoolList {

                //  Eintrag zur Auswahlbox hinzufuegen
                schoolNameComboBox.addItem(withObjectValue: school.name)
                //  zuletzt genutze Schule (ueber Namen) laden und selektieren
                //  Problem: Notify bevor Schule aus AddSchoolView neu zugewiesen
                let lastUsedSchoolName = userSettings.string(forKey: UserSettingsKeys.LAST_USED_SCHOOL_NAME)
                if !(lastUsedSchoolName?.isEmpty ?? true) {
                    if lastUsedSchoolName?.uppercased() == school.name.uppercased() {
                            
                            schoolNameComboBox.selectItem(at: index)
                            
                    }
                } else {
                    
                    //  ansonsten erste Schule der Liste als aktuelle setzen
                    schoolNameComboBox.selectItem(at: 0)
                    actualSchool = school
                    
                }
                index += 1
            }
            
            //  Anzahl der Faecher anzeigen
            let courseList = realm.objects(Course.self)
            if !courseList.isEmpty {
                
                countOfCourseLabel.stringValue = String(courseList.count)
                //  es wurde ein Fach angelegt -> erste Schritte Stufe 3
                if !isFirstStepCompleted { updateFirstStepLabel(firstStepValue: 3) }
                userSettings.set(3, forKey: UserSettingsKeys.FIRST_RUN_STEP)
                
            }
            
            //  Anzahl der zugeordneten Lehrer anzeigen
            let teacherCount = actualSchool?.teacher.count ?? 0
            countOfTeacherLabel.stringValue = String(teacherCount)
            //  es wurde ein Lehrer angelegt -> erste Schritte Stufe 4
            if !isFirstStepCompleted && teacherCount > 0 {
                
                userSettings.set(4, forKey: UserSettingsKeys.FIRST_RUN_STEP)
                updateFirstStepLabel(firstStepValue: 4)
                
            }
            
            //  Anzahl der zugeordneten Klassen anzeigen
            let schoolClassCount = actualSchool?.schoolClasses.count ?? 0
            countOfTeacherLabel.stringValue = String(schoolClassCount)
            //  es wurde eine Klasse angelegt -> erste Schritte Stufe 5
            if !isFirstStepCompleted && schoolClassCount > 0 {
                
                userSettings.set(5, forKey: UserSettingsKeys.FIRST_RUN_STEP)
                updateFirstStepLabel(firstStepValue: 5)
                
            }
            
            //  Anzahl der zugeordneten Schueler anzeigen
            var studentsCount: Int = 0
            if let schoolClassList = actualSchool?.schoolClasses {
                
                for schoolClass in schoolClassList {
                
                    studentsCount += schoolClass.student.count
            
                }
            }
            countOfStudentsLabel.stringValue = String(studentsCount)
            //  es wurde eine Klasse angelegt -> erste Schritte Stufe 99
            if !isFirstStepCompleted && studentsCount > 0 {
                
                userSettings.set(99, forKey: UserSettingsKeys.FIRST_RUN_STEP)
                updateFirstStepLabel(firstStepValue: 99)
                
            }
            
        }
        
    }
    
    private func updateFirstStepLabel(firstStepValue: Int) {
        
        //  erste Schritte - Label je nach Stufe ausblenden
        if isFirstStepCompleted {
            
            //  alle Label entfernen
            for index in 0...4 { firstStepLabelList[index].isHidden = true }
            
        } else {
            
            // je nach Stufe anpassen
            switch firstStepValue {
            case 1:
                for index in 1...4 { firstStepLabelList[index].isHidden = true }
            case 2:
                for index in 2...4 { firstStepLabelList[index].isHidden = true }
                firstStepLabel.isHidden = true
                secondStepLabel.isHidden = false
                addCourseButton.isEnabled = true
            case 3:
                for index in 0...1 { firstStepLabelList[index].isHidden = true }
                for index in 3...4 { firstStepLabelList[index].isHidden = true }
                thirdStepLabel.isHidden = false
                for index in 0...1 { firstStepButtonList[index].isEnabled = true }
            case 4:
                for index in 0...2 { firstStepLabelList[index].isHidden = true }
                fourthStepLabel.isHidden = false
                fivedStepLabel.isHidden = true
                for index in 0...2 { firstStepButtonList[index].isEnabled = true }
            case 5:
                for index in 0...3 { firstStepLabelList[index].isHidden = true }
                for index in 0...3 { firstStepButtonList[index].isEnabled = true }
                fivedStepLabel.isHidden = false
            default:
                for index in 0...4 { firstStepLabelList[index].isHidden = true }
                for index in 0...3 { firstStepButtonList[index].isEnabled = true }
            }
        }
        
    }
    
    //  wird bei Initalisieren der View aufgerufen
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //  erste Schritte
        if userSettings.integer(forKey: UserSettingsKeys.FIRST_RUN_STEP) > 5 {
            
            isFirstStepCompleted = true
            
        }
        firstStepLabelList = [firstStepLabel, secondStepLabel, thirdStepLabel, fourthStepLabel, fivedStepLabel]
        firstStepButtonList = [addCourseButton, addTeacherButton, addSchoolClassButton, addStudentButton]

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
                //  esrte Schritte aktivieren
                userSettings.setValue(1, forKey: UserSettingsKeys.FIRST_RUN_STEP)
                //  Hinweis an Nutzer
                let dialog = ModalOptionDialog(message: "Alle Daten wurden gelöscht! Konfiguration prüfen!",
                                               buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                               dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
                dialog.showDialog()
                
            }
            
            //  Schulen laden und in Auswahlbox darstellen
            let schoolList = realm.objects(School.self)
            if !schoolList.isEmpty {
               
                var index: Int = 0
                var isSelected: Bool = false
                for school in schoolList {

                    //  Eintrag zur Auswahlbox hinzufuegen
                    schoolNameComboBox.addItem(withObjectValue: school.name)
                    //  zuletzt genutze Schule (ueber Namen) laden und selektieren
                    let lastUsedSchoolName = userSettings.string(forKey: UserSettingsKeys.LAST_USED_SCHOOL_NAME)
                    if !(lastUsedSchoolName?.isEmpty ?? true) {
                        
                        if school.name.uppercased() == lastUsedSchoolName?.uppercased() {
                            
                            actualSchool = school
                            schoolNameComboBox.selectItem(at: index)
                            isSelected = true
                            
                        }
                        
                    }
                    
                    index += 1

                }
                
                //  ansonsten erste Schule aus Liste als aktuelle Schule setzen und selektieren
                if !isSelected {
                    
                    schoolNameComboBox.selectItem(at: 0)
                    actualSchool = schoolList[0]
                    
                }
                //  Anzahl der zugeordneten Klassen anzeigen
                countOfSchoolClassesLabel.stringValue = String(actualSchool?.schoolClasses.count ?? 0)
                
                //  Anzahl der zugeordneten Lehrer anzeigen
                countOfTeacherLabel.stringValue = String(actualSchool?.teacher.count ?? 0)
            }
           
            //  auf Aenderungen in der Auswahlbox (selbst) reagieren (extension:)
            schoolNameComboBox.delegate = self
            
            //  Anzahl der Faecher anzeigen
            let courseList = realm.objects(Course.self)
            if !courseList.isEmpty {
                
                countOfCourseLabel.stringValue = String(courseList.count)
                
            }
            
            //  Anzahl der zugeordneten Schueler anzeigen
            if !(actualSchool?.schoolClasses.isEmpty ?? true) {
                
                //  Test Realm-Query
                //  SELECT * FROM Students WHERE SchoolClass.name IN
                //          (SELECT SchoolClass.name FROM School WHERE name = "")
                //  
                
            }
            //countOfStudentsLabel.stringValue = String(actualSchool?.schoolClasses.count ?? 0)
            
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
        
        //  initial je nach Stufe die GUI anpassen
        updateFirstStepLabel(firstStepValue: userSettings.integer(forKey: UserSettingsKeys.FIRST_RUN_STEP))
        
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
            destinationViewController.actualSchool = actualSchool
            return
            
        }
        
        //  Ist das Ziel die AddTeacherView?
        if let destinationViewController = segue.destinationController as? AddTeacherViewController {
            
            //  Uebergabe der aktuellen Schule an die naechste View (den Controller)
            destinationViewController.actualSchool = actualSchool
            return

        }
        
        //  Ist das Ziel die AddStudentViewController?
        if let destinationViewController = segue.destinationController as? AddStudentViewController {
            
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
                    //  in Settings speichern
                    userSettings.set(actualSchool?.name, forKey: UserSettingsKeys.LAST_USED_SCHOOL_NAME)
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

