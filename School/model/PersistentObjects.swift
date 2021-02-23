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
//  bei Nutzung von Sync ist das Feld _id (string, int objectID) notwendig,
//  wird dynamisch erzeugt

internal class School: Object {
    
    @objc dynamic var _partition = ""
    @objc dynamic var _id = ObjectId.generate()
    @objc dynamic var name = ""
    //  an 1 Schule lernen 1 oder mehrere Schueler (1:n)
    //  diese lernen in Klasse, welche der Schule zugeordnet sind
    //  an 1 Schule gibt es 1 oder mehrere Klassen (1:n)
    let schoolClasses = List<SchoolClass>()
    //  an 1 Schule unterrichten 1 oder mehrere Lehrer (1:n)
    //  wird einem Lehrer eine Schule hinzugefuegt, so solllte die Liste der Lehrer
    //  automatisch aktualisiert werden -> "Inverse Relationship"
    let teacher = LinkingObjects(fromType: Teacher.self, property: "schools")
    
    override static func primaryKey() -> String? {
        return "_id"
    }
    
}

internal class Teacher: Object {
    
    @objc dynamic var _partition = ""
    @objc dynamic var _id = ObjectId.generate()
    @objc dynamic var firstName = ""
    @objc dynamic var lastName = ""
    //  1 Lehrer kann an mehreren Schulen unterrichten
    let schools = List<School>()
    //  1 Lehrer kann mehrere Faecher unterrichten
    let courses = List<Course>()

    override static func primaryKey() -> String? {
        return "_id"
    }
    
}

internal class Student: Object {
    
    @objc dynamic var _partition = ""
    @objc dynamic var _id = ObjectId.generate()
    @objc dynamic var firstName = ""
    @objc dynamic var lastName = ""
    //  die Schulklasse ist einer Schule zugeordnet
    @objc dynamic var schoolClass: SchoolClass?
    
    override static func primaryKey() -> String? {
        return "_id"
    }
    
}

internal class SchoolClass: Object {
    
    @objc dynamic var _partition = ""
    @objc dynamic var _id = ObjectId.generate()
    @objc dynamic var name = ""
    //  1 Klasse sollte genau 1 Lehrer haben (1:1)
    @objc dynamic var classTeacher: Teacher? = nil
    //  1 Klasse hat 1 oder mehrere Schueler
    let student = List<Student>()
    
    override static func primaryKey() -> String? {
        return "_id"
    }
    
}

internal class Course: Object {
    
    @objc dynamic var _partition = ""
    @objc dynamic var _id = ObjectId.generate()
    @objc dynamic var name = ""
    //  1 Fach kann von 1 oder mehreren Lehrern unterrichtet werden
    //  verweist auf Objekte vom Typ Lehrer, Eigenschaft im konkreten Objekt
    let lehrer = LinkingObjects(fromType: Teacher.self, property: "courses")
    
    override static func primaryKey() -> String? {
        return "_id"
    }
    
}

