//
//  PersistentObjects.swift
//  RealmTest
//
//  Created by mis on 15.02.21.
//
//  Copyright (c) [2021] [Michael Schmidt, michael.schmidt@app-making.de]
//  You can use it under the MIT License (You find it in file LICENSE)
//

import Foundation
import RealmSwift

//  Object aus Package RealmSwift, damit erreichen wir, das Objekte dieser Klasse
//  persistent gemacht werden können
//  Definitionen der Attribute (Eigenschaften) zur Verwendung mit Realm
//  id verwenden wir in allen Klassen als "Primaerschluessel",
//  bei Nutzung von Sync ist Feld id notwendig,
//  wird dynamisch erzeugt

internal class School: Object {
    
    @objc dynamic var id = ObjectId.generate()
    @objc dynamic var name = ""
    //  an 1 Schule lernen 1 oder mehrere Schueler (1:n)
    //  Liste der Schueler (List aus Package RealmSwift)
    let students = List<Student>()
    //  an 1 Schule gibt es 1 oder mehrere Klassen (1:n)
    let schoolClasses = List<SchoolClass>()
    //  an 1 Schule unterrichten 1 oder mehrere Lehrer (1:n)
    //  wird einem Lehrer eine Schule hinzugefuegt, so solllte die Liste der Lehrer
    //  automatisch aktualisiert werden -> "Inverse Relationship"
    let teacher = LinkingObjects(fromType: Teacher.self, property: "schools")
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}

internal class Teacher: Object {
    
    @objc dynamic var id = ObjectId.generate()
    @objc dynamic var firstName = ""
    @objc dynamic var lastName = ""
    //  1 Lehrer kann an mehreren Schulen unterrichten
    let schools = List<School>()
    //  1 Lehrer kann mehrere Faecher unterrichten
    let courses = List<Course>()

    override static func primaryKey() -> String? {
        return "id"
    }
    
}

internal class Student: Object {
    
    @objc dynamic var id = ObjectId.generate()
    @objc dynamic var firstName = ""
    @objc dynamic var lastName = ""
    //  1 Schueler kann (muss) in genau 1 Klasse sein (1:1)
    @objc dynamic var schoolClass: SchoolClass?
    //  1 Schueler kann (muss) genau 1 Schule besuchen (1:1)
    @objc dynamic var school: School?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}

internal class SchoolClass: Object {
    
    @objc dynamic var id = ObjectId.generate()
    @objc dynamic var name = ""
    //  1 Klasse sollte genau 1 Lehrer haben (1:1)
    @objc dynamic var classTeacher: Teacher? = nil
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}

internal class Course: Object {
    
    @objc dynamic var id = ObjectId.generate()
    @objc dynamic var name = ""
    //  1 Fach kann von 1 oder mehreren Lehrern unterrichtet werden
    //  verweist auf Objekte vom Typ Lehrer, Eigenschaft im konkreten Objekt
    let lehrer = LinkingObjects(fromType: Teacher.self, property: "courses")
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}

