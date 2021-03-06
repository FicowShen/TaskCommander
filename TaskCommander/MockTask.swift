import Foundation
import RxSwift
import TaskCommander

final class MockTask: Task {
    override func start() -> Observable<TaskProgress> {
        let subject = PublishSubject<TaskProgress>()
        DispatchQueue.global().async {
            let observer = subject.asObserver()
            let tryToFail = Bool.random()
            let failNow = { Int.random(in: 0...10) < 3 }
            for i in 0...100 {
                Thread.sleep(forTimeInterval: TimeInterval(Int.random(in: 1...10)) * 0.01)
                let taskProgress = TaskProgress(completedUnitCount: Int64(i), totalUnitCount: Int64(100))
                observer.onNext(taskProgress)
                if tryToFail && failNow() {
                    observer.onError(NSError(domain: "com.ficow.MockTask", code: -1, userInfo: [NSLocalizedDescriptionKey: "upload failed"]))
                    return
                }
            }
            observer.onCompleted()
        }
        return subject.asObservable()
    }
}
