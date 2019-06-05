import XCTest
import TaskCommander
import RxSwift
import RxCocoa
import RxTest
import RxBlocking

class UploadTaskTests: XCTestCase {

    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!

    override func setUp() {
        scheduler = TestScheduler(initialClock: 0, resolution: 1, simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }

    func testExample() {

    }

}
