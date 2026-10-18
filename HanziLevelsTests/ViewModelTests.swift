import XCTest

final class ViewModelTests: XCTestCase {
    @MainActor
    func testLevelSearchKeepsQueryAcrossModesAndResetsForANewVisit() async throws {
        let directory = try XCTUnwrap(Bundle(for: Self.self).resourceURL?.appendingPathComponent("Data", isDirectory: true))
        let library = Library()
        let viewModel = LevelViewModel(level: 1, library: library)
        XCTAssertEqual(viewModel.state, .loading)
        await library.load(directory: directory)
        XCTAssertEqual(viewModel.state, .ready)

        viewModel.query = "学"
        XCTAssertTrue(viewModel.words(for: .words).contains { $0.id == "学生" })
        XCTAssertTrue(viewModel.characters(for: .characters).contains { $0.id == "学" })
        XCTAssertTrue(viewModel.words(for: .characters).isEmpty)
        XCTAssertTrue(viewModel.characters(for: .words).isEmpty)
        XCTAssertEqual(viewModel.query, "学")

        let otherLevel = LevelViewModel(level: 5, library: library)
        otherLevel.query = "学生"
        XCTAssertTrue(otherLevel.words(for: .words).isEmpty)
        XCTAssertEqual(viewModel.query, "学")
        XCTAssertEqual(LevelViewModel(level: 1, library: library).query, "")
    }

    @MainActor
    func testSourcesRetryRestoresDocumentsAfterAFailedLoad() async throws {
        let directory = try XCTUnwrap(Bundle(for: Self.self).resourceURL?.appendingPathComponent("Data/Licenses", isDirectory: true))
        let viewModel = SourcesViewModel()
        XCTAssertNil(viewModel.documents)
        let missing = await viewModel.loadDocuments(directory: nil)
        XCTAssertEqual(missing, SourceDocument.allCases.count)
        XCTAssertEqual(viewModel.documents, [:])

        viewModel.retry()
        XCTAssertNil(viewModel.documents)
        XCTAssertEqual(viewModel.reloadID, 1)
        let recovered = await viewModel.loadDocuments(directory: directory)
        XCTAssertEqual(recovered, 0)
        XCTAssertEqual(viewModel.documents?.count, SourceDocument.allCases.count)
    }

    @MainActor
    func testCancelledSourcesLoadPreservesTheLastDocuments() async throws {
        let directory = try XCTUnwrap(Bundle(for: Self.self).resourceURL?.appendingPathComponent("Data/Licenses", isDirectory: true))
        let viewModel = SourcesViewModel()
        _ = await viewModel.loadDocuments(directory: directory)
        let previous = viewModel.documents
        let task = Task { await viewModel.loadDocuments(directory: nil) }
        task.cancel()
        let result = await task.value
        XCTAssertNil(result)
        XCTAssertEqual(viewModel.documents, previous)
    }
}
