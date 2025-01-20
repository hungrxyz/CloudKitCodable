//
//  CloudKitRecordDecoderTests.swift
//  CloudKitCodableTests
//
//  Created by Guilherme Rambo on 12/05/18.
//  Copyright © 2018 Guilherme Rambo. All rights reserved.
//

import XCTest
import CloudKit
@testable import CloudKitCodable

final class CloudKitRecordDecoderTests: XCTestCase {

    private func _validateDecodedPerson(_ person: Person) {
        XCTAssertEqual(person, Person.rambo)
        XCTAssertNotNil(person.cloudKitSystemFields, "\(_CKSystemFieldsKeyName) should bet set for a value conforming to CloudKitRecordRepresentable decoded from an existing CKRecord")
    }

    func testComplexPersonStructDecoding() throws {
        let person = try CloudKitRecordDecoder().decode(Person.self, from: CKRecord.testRecord)

        _validateDecodedPerson(person)
    }

    func testRoundTrip() throws {
        let encodedPerson = try CloudKitRecordEncoder().encode(Person.rambo)
        let samePersonDecoded = try CloudKitRecordDecoder().decode(Person.self, from: encodedPerson)

        _validateDecodedPerson(samePersonDecoded)
    }

    func testRoundTripWithCustomZoneID() throws {
        let zoneID = CKRecordZone.ID(zoneName: "ABCDE", ownerName: CKCurrentUserDefaultName)
        let encodedPerson = try CloudKitRecordEncoder(zoneID: zoneID).encode(Person.rambo)
        let samePersonDecoded = try CloudKitRecordDecoder().decode(Person.self, from: encodedPerson)
        let samePersonReencoded = try CloudKitRecordEncoder().encode(samePersonDecoded)

        _validateDecodedPerson(samePersonDecoded)

        XCTAssert(encodedPerson.recordID.zoneID == samePersonReencoded.recordID.zoneID)
    }

    func testCustomRecordIdentifierRoundTrip() throws {
        let zoneID = CKRecordZone.ID(zoneName: "ABCDE", ownerName: CKCurrentUserDefaultName)

        let record = try CloudKitRecordEncoder(zoneID: zoneID).encode(PersonWithCustomIdentifier.rambo)

        XCTAssert(record.recordID.zoneID == zoneID)
        XCTAssert(record.recordID.recordName == "MY-ID")

        let samePersonDecoded = try CloudKitRecordDecoder().decode(PersonWithCustomIdentifier.self, from: record)
        XCTAssert(samePersonDecoded.cloudKitIdentifier == "MY-ID")
    }

    func testEnumRoundtrip() throws {
        let model = TestModelWithEnum.allEnumsPopulated

        let record = try CloudKitRecordEncoder().encode(model)

        var sameModelDecoded = try CloudKitRecordDecoder().decode(TestModelWithEnum.self, from: record)
        sameModelDecoded.cloudKitSystemFields = nil

        XCTAssertEqual(sameModelDecoded, model)
    }

    func testNestedRoundtrip() throws {
        let model = TestParent.test

        let record = try CloudKitRecordEncoder().encode(model)

        var sameModelDecoded = try CloudKitRecordDecoder().decode(TestParent.self, from: record)
        sameModelDecoded.cloudKitSystemFields = nil

        XCTAssertEqual(sameModelDecoded, model)
    }

    func testNestedRoundtripOptionalChild() throws {
        let model = TestParentOptionalChild.test

        let record = try CloudKitRecordEncoder().encode(model)

        var sameModelDecoded = try CloudKitRecordDecoder().decode(TestParentOptionalChild.self, from: record)
        sameModelDecoded.cloudKitSystemFields = nil

        XCTAssertEqual(sameModelDecoded, model)
    }

    func testNestedRoundtripOptionalChildNil() throws {
        let model = TestParentOptionalChild.testNilChild

        let record = try CloudKitRecordEncoder().encode(model)

        var sameModelDecoded = try CloudKitRecordDecoder().decode(TestParentOptionalChild.self, from: record)
        sameModelDecoded.cloudKitSystemFields = nil

        XCTAssertEqual(sameModelDecoded, model)
    }

    func testNestedRoundtripCollection() throws {
        let model = TestParentCollection.test

        let record = try CloudKitRecordEncoder().encode(model)

        var sameModelDecoded = try CloudKitRecordDecoder().decode(TestParentCollection.self, from: record)
        sameModelDecoded.cloudKitSystemFields = nil

        XCTAssertEqual(sameModelDecoded, model)
    }

    func testCustomAssetRoundtrip() throws {
        let model = TestModelCustomAsset.test

        let record = try CloudKitRecordEncoder().encode(model)

        var sameModelDecoded = try CloudKitRecordDecoder().decode(TestModelCustomAsset.self, from: record)
        sameModelDecoded.cloudKitSystemFields = nil

        XCTAssertEqual(sameModelDecoded, model)
    }
    
    func testReferenceDecoding() throws {
        // given
        let record = CKRecord(recordType: "TestItem")
        record["field"] = UUID().uuidString
        
        let referenceID = CKRecord.ID(recordName: UUID().uuidString)
        let reference = CKRecord.Reference(recordID: referenceID, action: .deleteSelf)
        record["reference"] = reference
        
        let referenceIDs = [UUID(), UUID(), UUID()].map(\.uuidString)
        let references = referenceIDs.map {
            CKRecord.Reference(recordID: CKRecord.ID(recordName: $0), action: .deleteSelf)
        }
        record["references"] = references
        
        // when
        let item = try CloudKitRecordDecoder().decode(TestItem.self, from: record)
        
        // then
        XCTAssertEqual(item.field, record["field"] as? String)
        XCTAssertEqual(item.reference, referenceID.recordName)
        XCTAssertEqual(item.references, referenceIDs)
    }
    
    func testIdentifierAndDates() throws {
        // given
        let recordID = CKRecord.ID(recordName: UUID().uuidString)
        let record = CKRecord(recordType: "TestItem", recordID: recordID)
        
        struct Item: Decodable {
            let identifier: String
            let creationDate: Date?
            let modificationDate: Date?
        }
        
        // when
        let item = try CloudKitRecordDecoder().decode(Item.self, from: record)
        
        // then
        XCTAssertEqual(item.identifier, recordID.recordName)
        XCTAssertNil(item.creationDate)
        XCTAssertNil(item.modificationDate)
    }
    
}
