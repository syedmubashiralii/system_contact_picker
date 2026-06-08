import Flutter
import XCTest

@testable import system_contact_picker

class RunnerTests: XCTestCase {
  func testGetCapabilities() {
    let plugin = SystemContactPickerPlugin()
    let call = FlutterMethodCall(methodName: "getCapabilities", arguments: [])
    let resultExpectation = expectation(description: "result block must be called.")

    plugin.handle(call) { result in
      let capabilities = result as? [String: Any]
      XCTAssertEqual(capabilities?["platform"] as? String, "ios")
      XCTAssertEqual(capabilities?["supportsMultiple"] as? Bool, true)
      XCTAssertEqual(capabilities?["requiresReadContactsPermission"] as? Bool, false)
      resultExpectation.fulfill()
    }

    waitForExpectations(timeout: 1)
  }
}
