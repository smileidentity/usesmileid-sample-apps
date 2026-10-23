import Njia
import SampleUI
@testable import UseSmileIDSample
import XCTest

/// The shell's engine holder and the run's one exit, driven without a view.
@MainActor
final class UseSmileIDSampleNavigationTest: XCTestCase {
  private func model() throws -> UseSmileIDSampleNavigationModel {
    try UseSmileIDSampleNavigationModel(graph: UseSmileIDSampleNjiaSpec.graph())
  }

  private func steps(_ model: UseSmileIDSampleNavigationModel) -> [String] {
    model.state.entries.map(\.step)
  }

  func testAFreshFlowStartsOnTheProductsRoot() throws {
    XCTAssertEqual(try steps(model()), ["products"])
  }

  func testADetailLinkOpensOnItsTabRoot() throws {
    let model = try model()
    XCTAssertTrue(model.open("verifications/job-1", facts: []))
    XCTAssertEqual(steps(model), ["verifications", "verificationDetails"])
    XCTAssertEqual(model.state.top?.arg, "job-1")
  }

  func testASheetLinkOpensItsOwnerUnderIt() throws {
    let model = try model()
    XCTAssertTrue(model.open("settings/appearance", facts: []))
    XCTAssertEqual(steps(model), ["settings", "appearance"])
  }

  func testALinkKeepsTheStacksOfTheTabsItDidNotOpen() throws {
    let model = try model()
    model.open("profiles/p-2", facts: [])
    XCTAssertEqual(steps(model), ["settings", "profiles", "profileConfig"])
    model.open("products", facts: [])
    XCTAssertEqual(steps(model), ["products"])
    model.engine.select("settings")
    XCTAssertEqual(steps(model), ["settings", "profiles", "profileConfig"])
    XCTAssertEqual(model.state.top?.arg, "p-2")
  }

  func testALinkToAnotherTabDropsARunRatherThanParkingIt() throws {
    let model = try model()
    _ = try startedRun(model)
    model.open("settings", facts: [])
    model.engine.select("products")
    XCTAssertEqual(steps(model), ["products"])
  }

  func testALinkToAnotherTabKeepsTheFormsUnderARun() throws {
    let model = try model()
    let engine = model.engine
    let run = UseSmileIDSampleRunEntry(facts: [], step: UseSmileIDSampleStep.consentDetailsForm.rawValue)
    try engine.startRun(from: XCTUnwrap(engine.top), product: .smartSelfieEnrollment, run: run)
    try engine.next(XCTUnwrap(engine.top))
    XCTAssertEqual(steps(model), ["products", "consentDetailsForm", "sdkFlow"])
    model.open("settings", facts: [])
    model.engine.select("products")
    XCTAssertEqual(steps(model), ["products", "consentDetailsForm"])
  }

  func testALinkIntoTheSameTabReplacesItsStack() throws {
    let model = try model()
    model.open("profiles/p-2", facts: [])
    model.open("settings/licenses", facts: [])
    XCTAssertEqual(steps(model), ["settings", "licenses"])
  }

  func testARefusedLinkLeavesTheFlowAsItWas() throws {
    let model = try model()
    model.open("settings", facts: [])
    XCTAssertFalse(model.open("nope", facts: []))
    XCTAssertEqual(steps(model), ["settings"])
  }

  func testTheStateRestoresFromItsOwnEncoding() throws {
    let first = try model()
    first.open("verifications/job-1", facts: [])
    let second = try model()
    second.restore(from: first.encodedState())
    XCTAssertEqual(second.state, first.state)
  }

  func testUnreadableStateKeepsTheFreshFlow() throws {
    let model = try model()
    model.restore(from: "{not json")
    XCTAssertEqual(steps(model), ["products"])
  }

  func testALinkAlreadyOpenedIsNotOverwrittenByALaterRestore() throws {
    let saved = try model()
    saved.open("settings", facts: [])
    let model = try model()
    model.open("verifications", facts: [])
    model.restore(from: saved.encodedState())
    XCTAssertEqual(steps(model), ["verifications"])
  }

  func testTheStatePublishesEveryTransition() throws {
    let model = try model()
    let top = try XCTUnwrap(model.engine.top)
    model.engine.navigator(top).go(.scanToken)
    XCTAssertEqual(steps(model), ["products", "scanToken"])
  }

  func testARunsResultClearsProductsAndLandsOnTheVerificationsRoot() throws {
    let model = try model()
    let entry = try startedRun(model)
    SdkFlowExit(engine: model.engine, entry: entry, run: SdkFlowRun()).leave(landing: .verificationDetails, arg: "job-1")
    XCTAssertEqual(steps(model), ["verifications", "verificationDetails"])
    XCTAssertEqual(model.state.top?.arg, "job-1")
    XCTAssertEqual(model.state.parked["products"] ?? [], [])
  }

  func testACancelLandsOnTheProductsRoot() throws {
    let model = try model()
    let entry = try startedRun(model)
    SdkFlowExit(engine: model.engine, entry: entry, run: SdkFlowRun()).leave()
    XCTAssertEqual(steps(model), ["products"])
  }

  func testAnExitAfterTheRunHasLeftMovesNothing() throws {
    let model = try model()
    let entry = try startedRun(model)
    model.engine.select("settings")
    SdkFlowExit(engine: model.engine, entry: entry, run: SdkFlowRun()).leave()
    XCTAssertEqual(steps(model), ["settings"])
  }

  func testTheRunsProductIsReadFromItsFirstEntry() throws {
    let model = try model()
    let entry = try startedRun(model)
    XCTAssertEqual(model.engine.runProductId(entry), UseSmileIDSampleProduct.smartSelfieEnrollment.id)
  }

  /// A run of SmartSelfie Registration straight into the shell's flow step, as an autostart goes.
  private func startedRun(_ model: UseSmileIDSampleNavigationModel) throws -> NjiaEntry {
    let engine = model.engine
    let run = UseSmileIDSampleRunEntry(facts: [], step: UseSmileIDSampleStep.sdkFlow.rawValue)
    try engine.startRun(from: XCTUnwrap(engine.top), product: .smartSelfieEnrollment, run: run)
    let top = try XCTUnwrap(engine.top)
    XCTAssertEqual(top.step, "sdkFlow")
    return top
  }
}
