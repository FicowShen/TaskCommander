import XCTest
import TaskCommander
import RxSwift
import RxCocoa
import RxTest
import RxBlocking

class Tests: XCTestCase {

    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0, resolution: 1, simulateProcessingDelay: false)
        disposeBag = DisposeBag()
    }
    
    func testTwoNormalTaskCompleted() {
        let progress = scheduler.createObserver(TaskProgress.self)
        let commander = TaskCommander<MockTask>(subscribeScheduler: scheduler, observeScheduler: scheduler)
        var mockTasks = [MockTask]()

        let mockTask1 = MockTask()
        mockTask1.subject
            .asDriverOnErrorJustComplete()
            .drive(progress)
            .disposed(by: disposeBag)
        let mockTask2 = MockTask()
        mockTask2.subject
            .asDriverOnErrorJustComplete()
            .drive(progress)
            .disposed(by: disposeBag)
        mockTasks.append(mockTask1)
        mockTasks.append(mockTask2)

        switch mockTask1.state {
        case .ready: XCTAssertEqual(mockTask1.state.description, "ready")
        default: XCTFail()
        }

        commander.maxWorkingTasksCount = 1
        commander.addTasks(mockTasks)

        scheduler.createColdObservable([.next(10, TaskProgress(completedUnitCount: 10, totalUnitCount: 30)),
                                        .next(20, TaskProgress(completedUnitCount: 20, totalUnitCount: 30)),
                                        .next(30, TaskProgress(completedUnitCount: 30, totalUnitCount: 30)),
                                        .completed(40)])
            .bind(to: mockTask1.subject)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(15, TaskProgress(completedUnitCount: 1, totalUnitCount: 5)),
                                        .next(25, TaskProgress(completedUnitCount: 3, totalUnitCount: 5)),
                                        .next(35, TaskProgress(completedUnitCount: 5, totalUnitCount: 5)),
                                        .completed(45)])
            .bind(to: mockTask2.subject)
            .disposed(by: disposeBag)

        var workingStateCount = 0

        mockTask1.observable?
            .subscribe(onNext: { (taskState) in
            switch taskState {
            case .ready: break
            case .working:
                workingStateCount += 1
                XCTAssertEqual(taskState.description, "working")
            case .success:
                XCTAssertEqual(workingStateCount, 3)
            default: XCTFail()
            }
        }).disposed(by: disposeBag)

        scheduler.start()

        switch mockTask1.state {
        case .success: XCTAssertEqual(mockTask1.state.description, "success")
        default: XCTFail()
        }

        XCTAssertEqual(progress.events, [.next(10, TaskProgress(completedUnitCount: 10, totalUnitCount: 30)),
                                         .next(15, TaskProgress(completedUnitCount: 1, totalUnitCount: 5)),
                                         .next(20, TaskProgress(completedUnitCount: 20, totalUnitCount: 30)),
                                         .next(25, TaskProgress(completedUnitCount: 3, totalUnitCount: 5)),
                                         .next(30, TaskProgress(completedUnitCount: 30, totalUnitCount: 30)),
                                         .next(35, TaskProgress(completedUnitCount: 5, totalUnitCount: 5)),
                                         .completed(40),
                                         .completed(45)])
        XCTAssertEqual(Set(commander.currentTasks), Set(mockTasks))
    }

    func testTwoNormalTaskFailed() {
        let progress = scheduler.createObserver(TaskProgress.self)
        let commander = TaskCommander<MockTask>(subscribeScheduler: scheduler, observeScheduler: scheduler)
        var mockTasks = [MockTask]()

        let mockTask1 = MockTask()
        mockTask1.subject
            .asDriverOnErrorJustComplete()
            .drive(progress)
            .disposed(by: disposeBag)
        let mockTask2 = MockTask()
        mockTask2.subject
            .asDriverOnErrorJustComplete()
            .drive(progress)
            .disposed(by: disposeBag)
        mockTasks.append(mockTask1)
        mockTasks.append(mockTask2)

        commander.maxWorkingTasksCount = 3
        commander.addTasks(mockTasks)

        let error = NSError(domain: "Test", code: -1, userInfo: nil)
        scheduler.createColdObservable([.next(10, TaskProgress(completedUnitCount: 10, totalUnitCount: 20)),
                                        .next(20, TaskProgress(completedUnitCount: 20, totalUnitCount: 20)),
                                        .error(30, error)])
            .bind(to: mockTask1.subject)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(15, TaskProgress(completedUnitCount: 1, totalUnitCount: 5)),
                                        .next(25, TaskProgress(completedUnitCount: 5, totalUnitCount: 5)),
                                        .error(35, error)])
            .bind(to: mockTask2.subject)
            .disposed(by: disposeBag)

        scheduler.start()

        switch mockTask1.state {
        case .failure: XCTAssertEqual(mockTask1.state.description, "failure")
        default: XCTFail()
        }

        XCTAssertEqual(progress.events, [.next(10, TaskProgress(completedUnitCount: 10, totalUnitCount: 20)),
                                         .next(15, TaskProgress(completedUnitCount: 1, totalUnitCount: 5)),
                                         .next(20, TaskProgress(completedUnitCount: 20, totalUnitCount: 20)),
                                         .next(25, TaskProgress(completedUnitCount: 5, totalUnitCount: 5)),
                                         .completed(30),
                                         .completed(35)])
        let assertError = { (task: MockTask) in
            switch task.state {
            case .failure(let e as NSError): XCTAssertEqual(error, e)
            default: XCTFail()
            }
        }
        assertError(mockTask1)
        assertError(mockTask2)
    }

    func testNormalGroupTasks() {
        let taskInfo = scheduler.createObserver(GroupTaskInfo.self)
        let commander = TaskCommander<MockTask>(subscribeScheduler: scheduler, observeScheduler: scheduler)
        var mockTasks = [MockTask]()

        let mockTask1 = MockTask()
        let mockTask2 = MockTask()
        mockTasks.append(mockTask1)
        mockTasks.append(mockTask2)

        commander.addTasks(mockTasks)

        mockTasks.groupObservable
            .asDriverOnErrorJustComplete()
            .drive(taskInfo)
            .disposed(by: disposeBag)

        let error = NSError(domain: "Test", code: -1, userInfo: nil)

        scheduler.createColdObservable([.next(10, TaskProgress(completedUnitCount: 10, totalUnitCount: 30)),
                                        .next(20, TaskProgress(completedUnitCount: 20, totalUnitCount: 30)),
                                        .completed(40)])
            .bind(to: mockTask1.subject)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(15, TaskProgress(completedUnitCount: 1, totalUnitCount: 5)),
                                        .next(25, TaskProgress(completedUnitCount: 3, totalUnitCount: 5)),
                                        .error(45, error)])
            .bind(to: mockTask2.subject)
            .disposed(by: disposeBag)

        scheduler.start()
        XCTAssertEqual(taskInfo.events, [.next(45, GroupTaskInfo(successCount: 1, failureCount: 1)),
                                         .completed(45)])
    }
}


extension ObservableType {
    func asDriverOnErrorJustComplete() -> Driver<E> {
        return asDriver(onErrorRecover: { _ in Driver.empty() })
    }
}
