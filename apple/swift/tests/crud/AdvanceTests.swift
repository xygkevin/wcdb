/*
 * Tencent is pleased to support the open source community by making
 * WCDB available.
 *
 * Copyright (C) 2017 THL A29 Limited, a Tencent company.
 * All rights reserved.
 *
 * Licensed under the BSD 3-Clause License (the "License"); you may not use
 * this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 *       https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import XCTest
import WCDB

class AdvanceTests: CRUDTestCase {

    func testCoreStatement() {
        let statement = StatementSelect().select(Column.all).from(Master.builtinTableName)
        let optionalCoreStatement = WCDBAssertNoThrowReturned(try database.prepare(statement))
        XCTAssertNotNil(optionalCoreStatement)
    }

    func testCoreStatementRead() {
        // Give
        let statement = StatementSelect().select(Column.all).from(TestObject.name)
        let optionalCoreStatement = WCDBAssertNoThrowReturned(try database.prepare(statement))
        XCTAssertNotNil(optionalCoreStatement)
        let coreStatement = optionalCoreStatement!

        let expectedVariable1: Int32 = 1
        let expectedVariable2 = "object1"
        // When
        XCTAssertNoThrow(try coreStatement.step())
        // Then
        XCTAssertEqual(coreStatement.columnCount(), 2)

        XCTAssertEqual(coreStatement.columnName(atIndex: 0), "variable1")
        XCTAssertEqual(coreStatement.columnName(atIndex: 1), "variable2")

        XCTAssertEqual(coreStatement.columnTableName(atIndex: 0), TestObject.name)
        XCTAssertEqual(coreStatement.columnTableName(atIndex: 1), TestObject.name)

        XCTAssertEqual(coreStatement.index(byName: "variable1"), 0)
        XCTAssertEqual(coreStatement.index(byName: "variable2"), 1)
        XCTAssertNil(coreStatement.index(byName: "nonexistent"))

        XCTAssertEqual(coreStatement.columnType(atIndex: 0), ColumnType.integer64)
        XCTAssertEqual(coreStatement.columnType(atIndex: 1), ColumnType.text)
        XCTAssertEqual(coreStatement.columnType(byName: "variable1"), ColumnType.integer64)
        XCTAssertEqual(coreStatement.columnType(byName: "variable2"), ColumnType.text)
        XCTAssertEqual(coreStatement.columnType(byName: "nonexistent"), ColumnType.null)

        do {
            let variable1: Int32? = coreStatement.value(atIndex: 0)
            XCTAssertNotNil(variable1)
            XCTAssertEqual(variable1!, expectedVariable1)
            let variable2: String? = coreStatement.value(atIndex: 1)
            XCTAssertNotNil(variable2)
            XCTAssertEqual(variable2!, expectedVariable2)
        }

        do {
            let variable1: Int32? = coreStatement.value(byName: "variable1")
            XCTAssertNotNil(variable1)
            XCTAssertEqual(variable1!, expectedVariable1)
            let variable2: String? = coreStatement.value(byName: "variable2")
            XCTAssertNotNil(variable2)
            XCTAssertEqual(variable2!, expectedVariable2)
            let nonexistent: Int32? = coreStatement.value(byName: "nonexistent")
            XCTAssertNil(nonexistent)
        }

        coreStatement.finalize()
    }

    func testCoreStatementWrite() {
        // Give
        let bindParameters = BindParameter.bindParameters(2)
        let statement = StatementInsert().insert(intoTable: TestObject.name).values(bindParameters)
        let optionalCoreStatement = WCDBAssertNoThrowReturned(try database.prepare(statement))
        XCTAssertNotNil(optionalCoreStatement)
        let coreStatement = optionalCoreStatement!

        let expectedVariable1: Int32 = 3
        let expectedVariable2 = "object3"
        // When
        coreStatement.bind(nil, toIndex: 1)
        coreStatement.bind(expectedVariable2, toIndex: 2)
        XCTAssertNoThrow(try coreStatement.step())
        // Then
        XCTAssertEqual(coreStatement.lastInsertedRowID, 3)
        XCTAssertEqual(coreStatement.changes, 1)
        // When
        coreStatement.reset()
        let expectedObject = TestObject()
        expectedObject.variable1 = 4
        expectedObject.variable2 = "object4"
        XCTAssertNoThrow(try coreStatement.bind([TestObject.Properties.variable1], of: expectedObject))
        XCTAssertNoThrow(try coreStatement.bind(TestObject.Properties.variable2, of: expectedObject, toIndex: 2))
        XCTAssertNoThrow(try coreStatement.step())

        coreStatement.finalize()
        // Then
        do {
            let condition = TestObject.Properties.variable1 == expectedVariable1
            let result: TestObject? = WCDBAssertNoThrowReturned(
                try database.getObject(fromTable: TestObject.name, where: condition)
            )
            XCTAssertNotNil(result)
            XCTAssertEqual(result!.variable2, expectedVariable2)
        }
        do {
            let condition = TestObject.Properties.variable1 == expectedObject.variable1!
            let result: TestObject? = WCDBAssertNoThrowReturned(
                try database.getObject(fromTable: TestObject.name, where: condition)
            )
            XCTAssertNotNil(result)
            XCTAssertEqual(result!, expectedObject)
        }
    }

    class CoreStatementTypedObject: TableCodable, Named {
        var int32: Int32 = 1
        var int64: Int64 = 2
        var double: Double = 3.0
        var string: String = "4"
        var data: Data = "5".data(using: .ascii)!
        enum CodingKeys: String, CodingTableKey {
            typealias Root = CoreStatementTypedObject
            case int32
            case int64
            case double
            case string
            case data
            static let objectRelationalMapping = TableBinding(CodingKeys.self)
        }
    }

    func testCoreStatementType() {
        let tableName = CoreStatementTypedObject.name

        XCTAssertNoThrow(try database.create(table: tableName, of: CoreStatementTypedObject.self))
        XCTAssertNoThrow(try database.insert(objects: CoreStatementTypedObject(), intoTable: tableName))

        let statement = StatementSelect().select(Column.all).from(tableName)
        let coreStatement: CoreStatement? = WCDBAssertNoThrowReturned(try database.prepare(statement))
        XCTAssertNotNil(coreStatement)
        let wrappedCoreStatement = coreStatement!
        XCTAssertNoThrow(try wrappedCoreStatement.step())

        do {
            let v1: Int32? = wrappedCoreStatement.value(atIndex: 0)
            XCTAssertNotNil(v1)
            XCTAssertEqual(v1!, 1)

            let v2: Int64? = wrappedCoreStatement.value(atIndex: 1)
            XCTAssertNotNil(v2)
            XCTAssertEqual(v2!, 2)

            let v3: Double? = wrappedCoreStatement.value(atIndex: 2)
            XCTAssertNotNil(v3)
            XCTAssertEqual(v3!, 3.0)

            let v4: String? = wrappedCoreStatement.value(atIndex: 3)
            XCTAssertNotNil(v4)
            XCTAssertEqual(v4!, "4")

            let v5: Data? = wrappedCoreStatement.value(atIndex: 4)
            XCTAssertNotNil(v5)
            XCTAssertEqual(v5!, "5".data(using: .ascii)!)

            let v6: Data? = wrappedCoreStatement.value(atIndex: 5)
            XCTAssertNil(v6)
        }
        do {
            let v1: Value = wrappedCoreStatement.value(atIndex: 0)
            XCTAssertEqual(v1.int32Value, 1)

            let v2: Value = wrappedCoreStatement.value(atIndex: 1)
            XCTAssertEqual(v2.int64Value, 2)

            let v3: Value = wrappedCoreStatement.value(atIndex: 2)
            XCTAssertEqual(v3.doubleValue, 3.0)

            let v4: Value = wrappedCoreStatement.value(atIndex: 3)
            XCTAssertEqual(v4.stringValue, "4")

            let v5: Value = wrappedCoreStatement.value(atIndex: 4)
            XCTAssertEqual(v5.dataValue, "5".data(using: .ascii)!)

            let v6: Value = wrappedCoreStatement.value(atIndex: 5)
            XCTAssertEqual(v6.type, .null)
        }
    }

    func testFundamentalValue() {
        // Give
        let int32Value: Int32 = 1
        let int32FundamentalValue = Value(int32Value)
        XCTAssertEqual(int32FundamentalValue.int32Value, 1)
        XCTAssertEqual(int32FundamentalValue.int64Value, 1)
        XCTAssertEqual(int32FundamentalValue.doubleValue, 1.0)
        XCTAssertEqual(int32FundamentalValue.stringValue, "1")
        XCTAssertEqual(int32FundamentalValue.dataValue, "1".data(using: .ascii)!)
        XCTAssertEqual(int32FundamentalValue.type, .integer32)

        let int64Value: Int64 = 2
        let int64FundamentalValue = Value(int64Value)
        XCTAssertEqual(int64FundamentalValue.int32Value, 2)
        XCTAssertEqual(int64FundamentalValue.int64Value, 2)
        XCTAssertEqual(int64FundamentalValue.doubleValue, 2.0)
        XCTAssertEqual(int64FundamentalValue.stringValue, "2")
        XCTAssertEqual(int64FundamentalValue.dataValue, "2".data(using: .ascii)!)
        XCTAssertEqual(int64FundamentalValue.type, .integer64)

        let doubleValue: Double = 3.0
        let doubleFundamentalValue = Value(doubleValue)
        XCTAssertEqual(doubleFundamentalValue.int32Value, 3)
        XCTAssertEqual(doubleFundamentalValue.int64Value, 3)
        XCTAssertEqual(doubleFundamentalValue.doubleValue, 3.0)
        XCTAssertEqual(doubleFundamentalValue.stringValue, "3.0")
        XCTAssertEqual(doubleFundamentalValue.dataValue, "3.0".data(using: .ascii)!)
        XCTAssertEqual(doubleFundamentalValue.type, .float)

        let stringValue: String = "4"
        let stringFundamentalValue = Value(stringValue)
        XCTAssertEqual(stringFundamentalValue.int32Value, 4)
        XCTAssertEqual(stringFundamentalValue.int64Value, 4)
        XCTAssertEqual(stringFundamentalValue.doubleValue, 4.0)
        XCTAssertEqual(stringFundamentalValue.stringValue, "4")
        XCTAssertEqual(stringFundamentalValue.dataValue, "4".data(using: .ascii)!)
        XCTAssertEqual(stringFundamentalValue.type, .text)

        let dataValue: Data = "5".data(using: .ascii)!
        let dataFundamentalValue = Value(dataValue)
        XCTAssertEqual(dataFundamentalValue.int32Value, 0)
        XCTAssertEqual(dataFundamentalValue.int64Value, 0)
        XCTAssertEqual(dataFundamentalValue.doubleValue, 0)
        XCTAssertEqual(dataFundamentalValue.stringValue, "5")
        XCTAssertEqual(dataFundamentalValue.dataValue, "5".data(using: .ascii)!)
        XCTAssertEqual(dataFundamentalValue.type, .BLOB)

        let nullFundamentalValue = Value(nil)
        XCTAssertEqual(nullFundamentalValue.int32Value, 0)
        XCTAssertEqual(nullFundamentalValue.int64Value, 0)
        XCTAssertEqual(nullFundamentalValue.doubleValue, 0)
        XCTAssertEqual(nullFundamentalValue.stringValue, "")
        XCTAssertEqual(nullFundamentalValue.dataValue, "".data(using: .ascii)!)
        XCTAssertEqual(nullFundamentalValue.type, .null)
    }

    func testStepFailed() {
        // Give
        let bindParameters = BindParameter.bindParameters(2)
        let statement = StatementInsert().insert(intoTable: TestObject.name).values(bindParameters)
        let optionalCoreStatement = WCDBAssertNoThrowReturned(try database.prepare(statement))
        XCTAssertNotNil(optionalCoreStatement)
        let coreStatement = optionalCoreStatement!

        let expectedVariable2 = "object3"
        // When
        coreStatement.bind(nil, toIndex: 1)
        coreStatement.bind(expectedVariable2, toIndex: 2)
        XCTAssertNoThrow(try coreStatement.step())
        XCTAssertNoThrow(try coreStatement.step())
    }

    func testExecFailed() {
        let statement = StatementSelect().select(Column.all).from("nonexistentTable")
        XCTAssertThrowsError(try database.exec(statement))
    }

    func testCipher() {
        // Give
        XCTAssertNoThrow(try database.close {
            try self.database.removeFiles()
        })
        let password = "password".data(using: .ascii)!
        let wrongPassword = "wrongPassword".data(using: .ascii)!
        // When
        database.setCipher(key: password)
        XCTAssertNoThrow(try database.create(table: TestObject.name, of: TestObject.self))
        // Then
        database.close()
        database.setCipher(key: wrongPassword)
        XCTAssertThrowsError(try database.isTableExists(TestObject.name))

        database.close()
        database.setCipher(key: nil)
        XCTAssertThrowsError(try database.isTableExists(TestObject.name))

        database.close()
        database.setCipher(key: password)
        let exists = WCDBAssertNoThrowReturned(try database.isTableExists(TestObject.name))
        XCTAssertNotNil(exists)
        XCTAssertTrue(exists!)
    }

    func testCipherFailed() {
        // Give
        XCTAssertNoThrow(try database.close {
            try self.database.removeFiles()
            })
        let emptyPassword = Data()
        // When
        database.setCipher(key: emptyPassword)
        XCTAssertFalse(database.canOpen)
    }

    func testConfig() {
        // Then
        do {
            let optionalCoreStatement = WCDBAssertNoThrowReturned(
                try database.prepare(StatementPragma().pragma(.secureDelete))
            )
            XCTAssertNotNil(optionalCoreStatement)
            let coreStatement = optionalCoreStatement!
            XCTAssertNoThrow(try coreStatement.step())
            let isSecureDelete: Int32? = coreStatement.value(atIndex: 0)
            XCTAssertNotNil(isSecureDelete)
            XCTAssertEqual(isSecureDelete!, 0)
            coreStatement.finalize()
        }
        // Give
        database.close()
        database.setConfig(named: "SecureDelete") { (handle) throws in
            let statement = StatementPragma().pragma(.secureDelete).to(true)
            try handle.exec(statement)
        }
        // When
        XCTAssertTrue(database.canOpen)
        // Then
        do {
            let optionalCoreStatement = WCDBAssertNoThrowReturned(
                try database.prepare(StatementPragma().pragma(.secureDelete))
            )
            XCTAssertNotNil(optionalCoreStatement)
            let coreStatement = optionalCoreStatement!
            XCTAssertNoThrow(try coreStatement.step())
            let isSecureDelete: Int32? = coreStatement.value(atIndex: 0)
            XCTAssertNotNil(isSecureDelete)
            XCTAssertEqual(isSecureDelete!, 1)
            coreStatement.finalize()
        }
    }

    func testOrderedConfig() {
        // Then
        do {
            let optionalCoreStatement = WCDBAssertNoThrowReturned(
                try database.prepare(StatementPragma().pragma(.secureDelete))
            )
            XCTAssertNotNil(optionalCoreStatement)
            let coreStatement = optionalCoreStatement!
            XCTAssertNoThrow(try coreStatement.step())
            let isSecureDelete: Int32? = coreStatement.value(atIndex: 0)
            XCTAssertNotNil(isSecureDelete)
            XCTAssertEqual(isSecureDelete!, 0)
            coreStatement.finalize()
        }
        // Give
        database.close()
        database.setConfig(named: "SecureDelete", withInvocation: { (handle) throws in
            let statement = StatementPragma().pragma(.secureDelete).to(true)
            try handle.exec(statement)
        }, withPriority: .high)
        var tested = false
        database.setConfig(named: "test") { (handle) throws in

            let handleStatement: HandleStatement? = WCDBAssertNoThrowReturned(
                try handle.prepare(StatementPragma().pragma(.secureDelete))
            )
            XCTAssertNotNil(handleStatement)
            let wrappedHandleStatement = handleStatement!
            XCTAssertNoThrow(try wrappedHandleStatement.step())
            let isSecureDelete: Int32 = wrappedHandleStatement.columnValue(atIndex: 0)
            XCTAssertEqual(isSecureDelete, 1)
            wrappedHandleStatement.finalize()

            tested = true
        }
        // When
        XCTAssertTrue(database.canOpen)
        XCTAssertTrue(tested)
    }

    func testConfigChangeOrder() {
        // Give
        database.close()
        database.setConfig(named: "SecureDelete", withInvocation: { (_) throws in
            XCTFail("should not reach")
        })
        var tested = false
        database.setConfig(named: "test", withInvocation: { (handle) throws in
            // Then
            let handleStatement: HandleStatement? = WCDBAssertNoThrowReturned(
                try handle.prepare(StatementPragma().pragma(.secureDelete))
            )
            XCTAssertNotNil(handleStatement)
            let wrappedHandleStatement = handleStatement!
            XCTAssertNoThrow(try wrappedHandleStatement.step())
            let isSecureDelete: Int32 = wrappedHandleStatement.columnValue(atIndex: 0)
            XCTAssertEqual(isSecureDelete, 0)
            wrappedHandleStatement.finalize()

            tested = true
        }, withPriority: .high)
        database.setConfig(named: "SecureDelete", withInvocation: { (handle) throws in
            let statement = StatementPragma().pragma(.secureDelete).to(true)
            try handle.exec(statement)
        }, withPriority: .high)
        // When
        XCTAssertTrue(database.canOpen)
        XCTAssertTrue(tested)
    }

    func testConfigFailed() {
        // Give
        database.close()
        database.setConfig(named: "testConfigFailed", withInvocation: { (handle) throws in
            try handle.exec(StatementSelect().select(Column.all).from("nonexistentTable"))
        })
        // When
        XCTAssertFalse(database.canOpen)
    }

    func testRedirect() {
        let property = TestObject.Properties.any.count().as(TestObject.Properties.variable1)
        let optionalObject: TestObject? = WCDBAssertNoThrowReturned(
            try database.getObject(on: property, fromTable: TestObject.name)
        )
        XCTAssertNotNil(optionalObject)
        XCTAssertEqual(optionalObject!.variable1, preInsertedObjects.count)
    }

    func testRedirectCodingKey() {
        let property = TestObject.Properties.variable1.as(TestObject.Properties.variable1)
        let optionalObject: TestObject? = WCDBAssertNoThrowReturned(
            try database.getObject(on: property, fromTable: TestObject.name)
        )
        XCTAssertNotNil(optionalObject)
        XCTAssertEqual(optionalObject!.variable1, preInsertedObjects[0].variable1)
    }

//    class FTSObject: TestObjectBase, TableCodable {
//        var variable1: Int = 0
//        var variable2: String = ""
//
//        enum CodingKeys: String, CodingTableKey {
//            typealias Root = FTSObject
//            case variable1
//            case variable2
//            static let objectRelationalMapping = TableBinding(CodingKeys.self)
//            static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
//                return [.variable1: ColumnConstraintBinding(isPrimary: true,
//                                                            orderBy: .ascending,
//                                                            isAutoIncrement: true)]
//            }
//            static var virtualTableBinding: VirtualTableBinding? {
//                return VirtualTableBinding(with: .fts3, and: ModuleArgument(with: .WCDB))
//            }
//        }
//
//        override var hashValue: Int {
//            return (String(variable1)+variable2).hashValue
//        }
//    }
//    func testFTS() {
//        //Give
//        XCTAssertNoThrow(try database.close {
//            try self.database.removeFiles()
//        })
//        database.setTokenizes(.WCDB)
//        XCTAssertNoThrow(try database.create(virtualTable: FTSObject.name, of: FTSObject.self))
//
//        let preInsertedEnglishFTSObject: FTSObject = {
//            let object = FTSObject()
//            object.variable1 = 1
//            object.variable2 = "This is English test content"
//            return object
//        }()
//        let preInsertedChineseFTSObject: FTSObject = {
//            let object = FTSObject()
//            object.variable1 = 2
//            object.variable2 = "这是中文测试内容"
//            return object
//        }()
//        let preInsertedNumbericFTSObject: FTSObject = {
//            let object = FTSObject()
//            object.variable1 = 1
//            object.variable2 = "123456"
//            return object
//        }()
//        let preInsertedSymbolicFTSObject: FTSObject = {
//            let object = FTSObject()
//            object.variable1 = 1
//            object.variable2 = "abc..def"
//            return object
//        }()
//        let objects = [preInsertedEnglishFTSObject,
//                       preInsertedChineseFTSObject,
//                       preInsertedNumbericFTSObject,
//                       preInsertedSymbolicFTSObject]
//        XCTAssertNoThrow(try database.insert(objects: objects, intoTable: FTSObject.name))
//
//        //English
//        do {
//            //When
//            let condition = FTSObject.Properties.variable2.match("Engl*")
//            let objects = WCDBAssertNoThrowReturned(
//                try database.getObjects(fromTable: FTSObject.name, where: condition),
//                whenFailed: [FTSObject]()
//            )
//            //Then
//            XCTAssertEqual(objects.count, 1)
//            XCTAssertEqual(objects[0], preInsertedEnglishFTSObject)
//        }
//        //Chinese
//        do {
//            //When
//            let condition = FTSObject.Properties.variable2.match("中文*")
//            let objects = WCDBAssertNoThrowReturned(
//                try database.getObjects(fromTable: FTSObject.name, where: condition),
//                whenFailed: [FTSObject]()
//            )
//            //Then
//            XCTAssertEqual(objects.count, 1)
//            XCTAssertEqual(objects[0], preInsertedChineseFTSObject)
//        }
//        //Numberic
//        do {
//            //When
//            let condition = FTSObject.Properties.variable2.match("123*")
//            let objects = WCDBAssertNoThrowReturned(
//                try database.getObjects(fromTable: FTSObject.name, where: condition),
//                whenFailed: [FTSObject]()
//            )
//            //Then
//            XCTAssertEqual(objects.count, 1)
//            XCTAssertEqual(objects[0], preInsertedNumbericFTSObject)
//        }
//        //Symbolic
//        do {
//            //When
//            let condition = FTSObject.Properties.variable2.match("def")
//            let objects = WCDBAssertNoThrowReturned(
//                try database.getObjects(fromTable: FTSObject.name, where: condition),
//                whenFailed: [FTSObject]()
//            )
//            //Then
//            XCTAssertEqual(objects.count, 1)
//            XCTAssertEqual(objects[0], preInsertedSymbolicFTSObject)
//        }
//
//        //Find Chinese
//        do {
//            //When
//            let condition = FTSObject.Properties.variable2.match("文测")
//            let objects = WCDBAssertNoThrowReturned(
//                try database.getObjects(fromTable: FTSObject.name, where: condition),
//                whenFailed: [FTSObject]()
//            )
//            //Then
//            XCTAssertEqual(objects.count, 1)
//            XCTAssertEqual(objects[0], preInsertedChineseFTSObject)
//        }
//    }
}
