import Foundation
import RxSwift
import Alamofire
import RxAlamofire

public final class DownloadTask: Task {

    public let request: URLRequest
    public var data: Data?

    private let observeScheduler: SchedulerType

    private let dataRequestObservable: Observable<DataRequest>
    private var bag: DisposeBag?

    public init(request: URLRequest,
                sessionManager: SessionManager = SessionManager.default,
                observeScheduler: SchedulerType = MainScheduler.instance) {
        self.request = request
        self.observeScheduler = observeScheduler

        dataRequestObservable = sessionManager.rx
            .request(urlRequest: request)
            .validate(statusCode: 200..<300)
    }

    public override func start() -> Observable<TaskProgress> {
        let subject = PublishSubject<TaskProgress>()
        let observer = subject.asObserver()
        let bag = DisposeBag()
        self.bag = bag

        dataRequestObservable
            .skip(1)
            .flatMap { $0.rx.progress() }
            .observeOn(observeScheduler)
            .subscribe { [weak self] (event) in
                switch event {
                case .next(let progress):
                    let taskProgress = TaskProgress(completedUnitCount: progress.bytesWritten, totalUnitCount: progress.totalBytes)
                    observer.onNext(taskProgress)
                case .error(let error):
                    observer.onError(error)
                case .completed: break
                }
            }.disposed(by: bag)

        dataRequestObservable
            .flatMap { $0.rx.data() }
            .observeOn(observeScheduler)
            .subscribe { [weak self] (event) in
                defer {
                    observer.onCompleted()
                    self?.bag = nil
                }
                guard let data = event.element else { return }
                self?.data = data
            }.disposed(by: bag)

        return subject.asObservable()
    }
}
