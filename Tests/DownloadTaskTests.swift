import XCTest
import TaskCommander
import RxSwift
import RxCocoa
import RxTest
import RxBlocking
import Alamofire
import RxAlamofire
import OHHTTPStubs

private struct Dummy {
    static let DataJSONContent = "{\"hello\":\"world\", \"foo\":\"bar\", \"zero\": 0}"
    static let DataJSON = DataJSONContent.data(using: String.Encoding.utf8)!
}

class DownloadTaskTests: XCTestCase {

    var manager: SessionManager!
    var disposeBag: DisposeBag!

    let hostName = "myjsondata.com"
    let url = URL(string: "myjsondata.com")!

    override func setUp() {
        manager = SessionManager()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }

    func testDownload() {
        stub(condition: isMethodGET()) { _ in
            return OHHTTPStubsResponse(data: Dummy.DataJSON,
                                       statusCode: 200,
                                       headers: ["Content-Type":"application/json"])
        }
        let urlRequest = URLRequest(url: url)
        let task = DownloadTask(request: urlRequest,
                                sessionManager: manager)


        let commander = TaskCommander<DownloadTask>(subscribeScheduler: MainScheduler.instance, observeScheduler: MainScheduler.instance)
        commander.addTask(task)

        guard let taskStates = try? task.observable?.toBlocking().toArray() else {
            XCTFail("Load taskStates failed")
            return
        }

        let expectedStates = [TaskState.working(TaskProgress(completedUnitCount: 41, totalUnitCount: 41)), TaskState.success]
        XCTAssertEqual(taskStates.count, expectedStates.count)
        XCTAssertEqual(taskStates.first?.description, "working")
        XCTAssertEqual(taskStates.last?.description, "success")
        switch taskStates.first {
        case .some(.working(let progress)):
            XCTAssertEqual(progress.completedUnitCount, 41)
            XCTAssertEqual(progress.totalUnitCount, 41)
        default: XCTFail("task")
        }

        XCTAssertEqual(task.data?.count, 41)

    }

}
