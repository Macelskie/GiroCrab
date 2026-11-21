import XCTest
import GiroCrabCore
@testable import GiroCrabUI

/// The list filter "Nur ohne Beleg" (#590): bookings that have neither a
/// stored file nor a linked receipt.
@MainActor
final class MissingDocumentFilterTests: XCTestCase {
    private var model: AppModel!

    override func setUp() async throws {
        model = AppModel(options: LaunchOptions(arguments: ["--demo-seed"], environment: [:]))
        XCTAssertEqual(model.vaultState, .open)
        XCTAssertNil(model.errorMessage)
    }

    override func tearDown() async throws { model = nil }

    func testTheFilterShowsOnlyBookingsWithoutAReceipt() throws {
        let all = model.bookings.count
        let with = model.bookings.filter { $0.documentCount > 0 }.count
        XCTAssertGreaterThan(with, 0)
        XCTAssertEqual(model.filterSymbol, "line.3.horizontal.decrease")

        model.missingDocumentOnly = true
        XCTAssertTrue(model.currentFilter.withoutDocument)
        XCTAssertFalse(model.currentFilter.listHasFlow)
        XCTAssertEqual(model.bookings.count, all - with)
        XCTAssertTrue(model.bookings.allSatisfy { $0.documentCount == 0 })
        XCTAssertEqual(model.filterSymbol, "line.3.horizontal.decrease.circle.fill")
        XCTAssertTrue(model.hasActiveListFilters)

        // a linked receipt takes its booking off the list
        let booking = try XCTUnwrap(model.bookings.first)
        XCTAssertNil(model.attachLink("https://archiv.example/documents/7", title: "", to: booking))
        XCTAssertFalse(model.bookings.contains { $0.id == booking.id })

        // "Filter zurücksetzen" (#840) clears it like every other list filter
        model.resetListFilters()
        XCTAssertFalse(model.missingDocumentOnly)
        XCTAssertEqual(model.bookings.count, all)
    }
}
