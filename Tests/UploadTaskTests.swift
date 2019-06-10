import XCTest
import TaskCommander
import RxSwift
import RxCocoa
import RxTest
import RxBlocking
import Alamofire
import RxAlamofire

class UploadTaskTests: XCTestCase {

    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!

    let urlString = "https://www.googleapis.com/upload/drive/v2/files?uploadType=multipart"
    let textContent = String(repeating: "test", count: 10)

    override func setUp() {
        scheduler = TestScheduler(initialClock: 0, resolution: 1, simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }

    func testUploadTaskWithRequest() {
        guard let url = URL(string: urlString),
            let data = textContent.data(using: .utf8)
            else {
            XCTFail("Load url/data failed")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let task = UploadTask(request: request, data: data)
        startUploadTask(task)
    }

    func testUploadTaskWithURLString() {
        guard let data = textContent.data(using: .utf8),
            let task = UploadTask(urlString: urlString, data: data)
            else {
                XCTFail("Load data/task failed")
                return
        }
        startUploadTask(task)
    }

    func startUploadTask(_ task: UploadTask) {
        let commander = TaskCommander<UploadTask>(subscribeScheduler: MainScheduler.instance, observeScheduler: MainScheduler.instance)
        commander.addTask(task)

        guard let taskStates = try? task.observable?.toBlocking().toArray() else {
            XCTFail("Load taskStates failed")
            return
        }

        XCTAssertTrue(taskStates.count > 1)

        let expectedStates = [TaskState.working(TaskProgress(completedUnitCount: 40, totalUnitCount: 40)), TaskState.success]
        XCTAssertEqual(taskStates.count, expectedStates.count)
        XCTAssertEqual(taskStates.first?.description, "working")
        XCTAssertEqual(taskStates.last?.description, "success")
        switch taskStates.first {
        case .some(.working(let progress)):
            XCTAssertEqual(progress.completedUnitCount, 40)
            XCTAssertEqual(progress.totalUnitCount, 40)
        default: XCTFail("task")
        }

        XCTAssertEqual(task.data.count, 40)
    }

}
