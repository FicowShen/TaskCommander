import Foundation
import RxSwift
import TaskCommander

final class MockTask: Task {

    let subject = PublishSubject<TaskProgress>()

    override func start() -> Observable<TaskProgress> {
        return subject.asObservable()
    }
}
