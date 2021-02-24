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
    
    @IBOutlet weak var cloudSyncButton: NSButton!
    @IBOutlet weak var cloudSyncLabel: NSTextField!
    
    //  Label und Variablen fuer die ersten Schritte
    //  bei jeder neuen Schule wieder aktivieren
    private var isFirstStepCompleted: Bool = false
    private var firstStepLabelList = [NSTextField]()
    private var firstStepButtonList = [NSButton]()
    
    //  Realm - wird entweder im Main-Controller oder
    //  bei Cloud-Nutzung im RealmSyncViewController initialisiert
    private var userRealm: Realm?
    
    //  aktuelle Schule, fuer Uebergabe an andere Controller
    internal var actualSchool: School?
    //  unsere Daten
    private var schoolList: Results<School>?
    private var courseList: Results<Course>?
    
    //  Benutzer- und Programmeinstellungen speichern
    private var userSettings = UserDefaults.standard
    
    //  Benachrichtigungen bei Aenderungen in der "Datenbank"
    private var realmAllNotificationsToken: NotificationToken?
    
    //  Initialisierung der View beim Start der App
    private func initializeView() {
        
        //  Stufe der ersten Schritte ermitteln
        // und View entsprechend anpassen
        var firstStepValue: Int = 1
        if UserSettings.keyExists(UserSettings.FIRST_RUN_STEP) {
            
            firstStepValue = userSettings.integer(forKey: UserSettings.FIRST_RUN_STEP)
            
        }
        switch firstStepValue {
        case 1:
            isFirstStepCompleted = false
            updateFirstStepLabel(firstStepValue: 1)
        case 2:
            isFirstStepCompleted = false
            updateFirstStepLabel(firstStepValue: 2)
        case 3:
            isFirstStepCompleted = false
            updateFirstStepLabel(firstStepValue: 3)
        case 4:
            isFirstStepCompleted = false
            updateFirstStepLabel(firstStepValue: 4)
        case 5:
            isFirstStepCompleted = false
            updateFirstStepLabel(firstStepValue: 5)
        case 99:
            isFirstStepCompleted = true
            updateFirstStepLabel(firstStepValue: 99)
        default:
            isFirstStepCompleted = false
            updateFirstStepLabel(firstStepValue: 1)
            userSettings.setValue(1, forKey: UserSettings.FIRST_RUN_STEP)
            
        }
        
        //  Auswahlbox initialisieren
        if !(schoolList?.isEmpty ?? true) {
            
            var index: Int = 0
            var isSelected: Bool = false
            var lastActualSchoolName: String
            if UserSettings.keyExists(UserSettings.LAST_USED_SCHOOL_NAME) {
                
                lastActualSchoolName = userSettings.string(forKey: UserSettings.LAST_USED_SCHOOL_NAME) ?? ""
                
            } else {
                
                lastActualSchoolName = ""
                
            }
            
            for school in schoolList! {
                
                schoolNameComboBox.addItem(withObjectValue: school.name)
                if lastActualSchoolName.uppercased() == school.name.uppercased() {
                    
                    actualSchool = school
                    schoolNameComboBox.selectItem(at: index)
                    isSelected = true
                    
                }
                index += 1
                
            }
            if !isSelected { schoolNameComboBox.selectItem(at: index) }
        }
        
        
    }
    
    // Aktualisierung der View - Schulen
    private func updateSchoolComboBox() {
        
        var index: Int = 0
        var isSelected: Bool = false
        var lastActualSchoolName: String
        if UserSettings.keyExists(UserSettings.LAST_USED_SCHOOL_NAME) {
            
            lastActualSchoolName = userSettings.string(forKey: UserSettings.LAST_USED_SCHOOL_NAME) ?? ""
            
        } else {
            
            lastActualSchoolName = ""
            
        }
        
        //  wurde eine Schule neu angelegt?
        if schoolNameComboBox.numberOfItems < schoolList?.count ?? 0 {
            
            for school in schoolList! {
                
                if lastActualSchoolName.uppercased() == school.name.uppercased() {
                    
                    schoolNameComboBox.addItem(withObjectValue: school.name)
                    schoolNameComboBox.selectItem(at: index)
                    isSelected = true
                    
                }
                index += 1
                
            }
            
            if !isSelected {
                
                schoolNameComboBox.selectItem(at: index)
                
            }
            userSettings.set(2, forKey: UserSettings.FIRST_RUN_STEP)
            updateFirstStepLabel(firstStepValue: 2)
            
        } else {
            
            //  neue Schule in Auswahlbox gewaehlt?
            for school in schoolList! {
                
                if school.name.uppercased() == lastActualSchoolName.uppercased() {
                    
                    self.actualSchool = school
                    
                }
                
            }
            
        }
        
    }
    
    //  Aktualisierung der View - Faecher, Klassen und Schuler
    private func updateView() {
        
        //  Anzahl der Faecher anzeigen
        countOfCourseLabel.stringValue = String(courseList?.count ?? 0)
        if !isFirstStepCompleted {
           
            if courseList?.count ?? 0 > 0 {
            
                userSettings.set(3, forKey: UserSettings.FIRST_RUN_STEP)
                updateFirstStepLabel(firstStepValue: 3)
                
            }
            
        }
        
        //  Anzahl der zugeordneten Lehrer anzeigen
        let teacherCount = actualSchool?.teacher.count ?? 0
        countOfTeacherLabel.stringValue = String(teacherCount)
        
        if !isFirstStepCompleted {
            
            //  es wurde ein Lehrer angelegt -> erste Schritte Stufe 4
            if UserSettings.keyExists(UserSettings.FIRST_RUN_STEP) {
                
                if teacherCount > 0 && userSettings.integer(forKey: UserSettings.FIRST_RUN_STEP) == 3 {
                
                userSettings.set(4, forKey: UserSettings.FIRST_RUN_STEP)
                updateFirstStepLabel(firstStepValue: 4)
                
                }
                
            }
            
        }
        
        //  Anzahl der zugeordneten Klassen anzeigen
        let schoolClassCount = actualSchool?.schoolClasses.count ?? 0
        countOfSchoolClassesLabel.stringValue = String(schoolClassCount)
        //  es wurde eine Klasse angelegt -> erste Schritte Stufe 5
        if !isFirstStepCompleted && schoolClassCount > 0 {
            
            userSettings.set(5, forKey: UserSettings.FIRST_RUN_STEP)
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
            
            userSettings.set(99, forKey: UserSettings.FIRST_RUN_STEP)
            updateFirstStepLabel(firstStepValue: 99)
            
        }

    }

    //  Label je nach Stufe der "Ersten Schritte" anpassen
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
                for index in 0...3 { firstStepButtonList[index].isEnabled = false }
            case 2:
                for index in 2...4 { firstStepLabelList[index].isHidden = true }
                firstStepLabel.isHidden = true
                secondStepLabel.isHidden = false
                for index in 1...3 { firstStepButtonList[index].isEnabled = false }
                addCourseButton.isEnabled = true
            case 3:
                for index in 0...1 { firstStepLabelList[index].isHidden = true }
                for index in 3...4 { firstStepLabelList[index].isHidden = true }
                thirdStepLabel.isHidden = false
                for index in 0...1 { firstStepButtonList[index].isEnabled = true }
                addTeacherButton.isEnabled = true
                for index in 2...3 { firstStepButtonList[index].isEnabled = false }
                
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
        
        //  Label fuer die "Ersten Schritte"
        firstStepLabelList = [firstStepLabel, secondStepLabel, thirdStepLabel, fourthStepLabel, fivedStepLabel]
        firstStepButtonList = [addCourseButton, addTeacherButton, addSchoolClassButton, addStudentButton]

        //  auf Aenderungen in der Auswahlbox (selbst) reagieren (extension:)
        schoolNameComboBox.delegate = self
        
        //  Verwendung von Cloud-Sync
        var useCloudSync: Bool = false
        if RealmAppSettings.USE_REALM_SYNC {
                
                //  Anwendung unterstuetzt Cloud-Sync - Dev
                //  Label und Checkbox aktivieren
                cloudSyncLabel.isHidden = false
                cloudSyncButton.isHidden = false
                
            //  Nutzer hat es auch aktiviert?
            if UserSettings.keyExists(UserSettings.USE_REALM_SYNC) {
                
                if userSettings.bool(forKey: UserSettings.USE_REALM_SYNC) {
                    
                    cloudSyncButton.state = NSControl.StateValue.on
                    useCloudSync = true
                    
                    //  Nutzer muss sich anmelden
                    //  RealmSyncLoginView anzeigen und Cloud-Sync aktivieren
                    //  userRealm wird als Cloud-Sync aktiviert
                    let sequeID = NSStoryboardSegue.Identifier("Main2RealmSyncSeque")
                    performSegue(withIdentifier: sequeID, sender: self)
                    
                }
                
            }
            
        }
        if !useCloudSync {
                
            //  userRealm wird lokal aktiviert
            do {
                
                //  waehrend der Entwicklung bei Schema-Aenderungen alle bisherigen Daten loeschen
                let configuration = Realm.Configuration(deleteRealmIfMigrationNeeded: true)
                userRealm = try Realm(configuration: configuration)
                
                //  Daten loeschen - fuer Test und Entwicklung
                if REMOVE_REALM_DATA {
                    
                    userRealm?.beginWrite()
                    userRealm?.deleteAll()
                    try userRealm?.commitWrite()
                    //  Erste Schritte aktivieren - Stufe 1 (Schule anlegen)
                    isFirstStepCompleted = false
                    userSettings.set(1, forKey: UserSettings.FIRST_RUN_STEP)
                    //  Hinweis an Nutzer
                    let dialog = ModalOptionDialog(message: "Alle Daten wurden gelöscht! Bitte Konfiguration anpassen!",
                                                   buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                                   dialogStyle: ModalOptionDialog.DialogStyle.WARNING)
                    dialog.showDialog()
                    
                }
                
                //  Daten (aus lokalem) Realm laden
                schoolList = userRealm?.objects(School.self)
                courseList = userRealm?.objects(Course.self)

                /* Bug? Funktioniert nicht aus modalen Views
                https://github.com/realm/realm-cocoa/issues/7054
                //  Realm-Benachrichtigungen, hier Schule
                realmSchoolCollectionNotificationToken = schoolList.observe { [weak self] (changes: RealmCollectionChange) in*/
                
                //  Realm-Benachrichtigungen (fuer lokalen Realm), hier alle Aenderungen
                realmAllNotificationsToken = userRealm?.observe { notification, realm in
                    self.updateView()
                }
                
                //  View mit lokalem Realm inititalisieren
                initializeView()
                updateView()
                
            } catch {
                
                //  Fehler beim Zugriff auf die "Datenbank"
                let dialog = ModalOptionDialog(message: error.localizedDescription,
                                               buttonStyle: ModalOptionDialog.ButtonStyle.OK_OPTION,
                                               dialogStyle: ModalOptionDialog.DialogStyle.CRITICAL)
                dialog.showDialog()
                
            }
            
        }
 
    }
    
    //  wird vor Uebergabe an naechsten Controller aufgerufen
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        //  Ist das Ziel die RealmSyncLoginView?
        if let destinationViewController = segue.destinationController as? RealmSyncLoginViewController {
            
            //  Delegate "anmelden"
            destinationViewController.delegate = self
            return
            
        }
        
        //  Ist das Ziel die AddSchoolView?
        if let destinationViewController = segue.destinationController as? AddSchoolViewController {
            
            //  Uebergabe des MainViewControllers an die naechste View (den Controller)
            destinationViewController.delegate = self
            destinationViewController.userRealm = self.userRealm
            return
            
        }
        
        //  Ist das Ziel die AddSchoolView?
        if let destinationViewController = segue.destinationController as? AddCourseViewController {
            
            //  Uebergabe des MainViewControllers an die naechste View (den Controller)
            destinationViewController.userRealm = self.userRealm
            return
            
        }
        
        //  Ist das Ziel die AddClassView?
        if let destinationViewController = segue.destinationController as? AddClassViewController {
            
            //  Uebergabe der aktuellen Schule an die naechste View (den Controller)
            destinationViewController.actualSchool = self.actualSchool
            destinationViewController.userRealm = self.userRealm
            return
            
        }
        
        //  Ist das Ziel die AddTeacherView?
        if let destinationViewController = segue.destinationController as? AddTeacherViewController {
            
            //  Uebergabe der aktuellen Schule an die naechste View (den Controller)
            destinationViewController.actualSchool = self.actualSchool
            destinationViewController.userRealm = self.userRealm
            return

        }
        
        //  Ist das Ziel die AddStudentView?
        if let destinationViewController = segue.destinationController as? AddStudentViewController {
            
            //  Uebergabe der aktuellen Schule an die naechste View (den Controller)
            destinationViewController.actualSchool = self.actualSchool
            destinationViewController.userRealm = self.userRealm
            return

        }
        
    }
    
    @IBAction func cloudSyncButtonClicked(_ sender: NSButton) {
        
        if cloudSyncButton.state == NSControl.StateValue.on {
        
            //  Main2RealmSyncSeque ausfuehren
            let sequeID = NSStoryboardSegue.Identifier("Main2RealmSyncSeque")
            performSegue(withIdentifier: sequeID, sender: self)
            
        }
        
    }

    override func viewDidDisappear() {
        
        realmAllNotificationsToken?.invalidate()
        
    }

}

//  Erweiterug des Controllers zur Interaktion mit der Auswahlbox
extension MainViewController: NSComboBoxDelegate {
    
    //  neue Schule (Name) in der Auswahlbox gewaehlt
    internal func comboBoxSelectionDidChange(_ notification: Notification) {
    
        if let schoolName = schoolNameComboBox.objectValueOfSelectedItem as? String {
        
            //  Namen der aktuellen Schule speicherm
            userSettings.set(schoolName, forKey: UserSettings.LAST_USED_SCHOOL_NAME)
            //  View aktualisieren
            updateSchoolComboBox()
            updateView()
                    
        }

    }
    
}
extension MainViewController: RealmDelegate {
    
    //  wenn in der RealmSyncLoginView ein Cloud-Realm initialisiert wurde
    func cloudRealmWasInit(_ userRealm: Realm) {
        
        //  Wert der Klassenvariablen zuweisen
        self.userRealm = userRealm
        
        //  Daten aus Cloud-Realm laden
        schoolList = userRealm.objects(School.self)
        courseList = userRealm.objects(Course.self)

        /* Bug? Funktioniert nicht aus modalen Views
        https://github.com/realm/realm-cocoa/issues/7054
        //  Realm-Benachrichtigungen, hier Schule
        realmSchoolCollectionNotificationToken = schoolList.observe { [weak self] (changes: RealmCollectionChange) in*/
        
        //  Realm-Benachrichtigungen, hier alle Aenderungen
        realmAllNotificationsToken = userRealm.observe { notification, realm in
            self.updateView()
        }
        
        //  View initialisieren mit Cloud-Realm
        initializeView()
        updateView()
                
    }
    
    //  wenn in der AddSchoolView eine neue Schule angelegt wurde
    func schoolWasAdded(_ school: School) {
        
        self.actualSchool = school
        updateSchoolComboBox()
        updateView()
    
    }
    
}
