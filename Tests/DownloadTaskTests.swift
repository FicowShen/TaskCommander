import XCTest
import TaskCommander
import RxSwift
import RxCocoa
import RxTest
import RxBlocking
import Alamofire
import RxAlamofire

class DownloadTaskTests: XCTestCase {

    var manager: SessionManager!
    var disposeBag: DisposeBag!

    let fileURL = "https://raw.githubusercontent.com/ReactiveX/RxSwift/master/assets/Rx_Logo_M.png"
    lazy var url = URL(string: fileURL)!

    override func setUp() {
        manager = SessionManager()
        disposeBag = DisposeBag()
    }

    func testDownloadTaskWithURLString() {

        guard let task = DownloadTask(urlString: fileURL, sessionManager: manager) else {
            XCTFail("Failed to load DownloadTask")
            return
        }
        startDownloadTask(task)
    }

    func testDownloadTaskWithRequest() {
        let urlRequest = URLRequest(url: url)
        let task = DownloadTask(request: urlRequest,
                                sessionManager: manager)
        startDownloadTask(task)
    }

    func startDownloadTask(_ task: DownloadTask) {
        let commander = TaskCommander<DownloadTask>(subscribeScheduler: MainScheduler.instance, observeScheduler: MainScheduler.instance)
        commander.addTask(task)

        guard let taskStates = try? task.observable?.toBlocking().toArray(),
            let data = task.data else {
            XCTFail("Download failed")
            return
        }

        XCTAssertTrue(taskStates.count > 1)
        guard let firstWorkingIndex = taskStates.firstIndex(where: { (taskState) -> Bool in taskState.description == "working" }) else {
            XCTFail("Load firstWorkingIndex failed")
            return
        }
        guard let firstSuccessIndex = taskStates.firstIndex(where: { (taskState) -> Bool in taskState.description == "success" }) else {
            XCTFail("Load firstSuccessIndex failed")
            return
        }
        XCTAssertTrue(firstWorkingIndex < firstSuccessIndex)

        switch taskStates[firstWorkingIndex] {
        case .working(let progress):
            XCTAssertEqual(progress.completedUnitCount, Int64(data.count))
            XCTAssertEqual(progress.totalUnitCount, Int64(data.count))
        default: XCTFail("task")
        }

    }

}