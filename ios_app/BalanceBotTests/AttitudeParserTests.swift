import XCTest
@testable import BalanceBot

final class AttitudeParserTests: XCTestCase {
    
    func testParseValidRollPitch() {
        let input = "R:12.3 P:-4.5"
        let result = AttitudeParser.parse(input)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.roll, 12.3, accuracy: 0.001)
        XCTAssertEqual(result?.pitch, -4.5, accuracy: 0.001)
        XCTAssertEqual(result?.yaw, 0.0, accuracy: 0.001)
    }
    
    func testParseWithYaw() {
        let input = "R:1.0 P:2.0 Y:45.5"
        let result = AttitudeParser.parse(input)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.roll, 1.0, accuracy: 0.001)
        XCTAssertEqual(result?.pitch, 2.0, accuracy: 0.001)
        XCTAssertEqual(result?.yaw, 45.5, accuracy: 0.001)
    }
    
    func testParseWithNewline() {
        let input = "R:10.0 P:20.0\r\n"
        let result = AttitudeParser.parse(input)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.roll, 10.0, accuracy: 0.001)
        XCTAssertEqual(result?.pitch, 20.0, accuracy: 0.001)
    }
    
    func testParseMissingRoll() {
        let input = "P:-4.5"
        let result = AttitudeParser.parse(input)
        
        XCTAssertNil(result)
    }
    
    func testParseMissingPitch() {
        let input = "R:12.3"
        let result = AttitudeParser.parse(input)
        
        XCTAssertNil(result)
    }
    
    func testParseInvalidFormat() {
        let input = "Hello World"
        let result = AttitudeParser.parse(input)
        
        XCTAssertNil(result)
    }
    
    func testParseEmptyString() {
        let input = ""
        let result = AttitudeParser.parse(input)
        
        XCTAssertNil(result)
    }
    
    func testParseNegativeValues() {
        let input = "R:-45.5 P:-30.2 Y:-90.0"
        let result = AttitudeParser.parse(input)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.roll, -45.5, accuracy: 0.001)
        XCTAssertEqual(result?.pitch, -30.2, accuracy: 0.001)
        XCTAssertEqual(result?.yaw, -90.0, accuracy: 0.001)
    }
}
