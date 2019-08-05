import Foundation
import RxSwift
import Alamofire
import RxAlamofire

public final class DownloadTask: Task {

    public let request: URLRequest
    public let dataRequestObservable: Observable<DataRequest>
    public private(set) var data: Data?

    private let observeScheduler: SchedulerType
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

    public convenience init?(urlString: String,
                             sessionManager: SessionManager = SessionManager.default,
                             observeScheduler: SchedulerType = MainScheduler.instance) {
        guard let url = URL(string: urlString)
            else { return nil }
        self.init(request: URLRequest(url: url),
                  sessionManager: sessionManager,
                  observeScheduler: observeScheduler)
    }

    public override func start() -> Observable<TaskProgress> {
        let subject = PublishSubject<TaskProgress>()
        let observer = subject.asObserver()
        let bag = DisposeBag()
        self.bag = bag

        dataRequestObservable
            .flatMap { $0.rx.progress() }
            .observeOn(observeScheduler)
            .subscribe { (event) in
                switch event {
                case .next(let progress):
                    guard progress.totalBytes > 0 else { return }
                    let taskProgress = TaskProgress(completedUnitCount: progress.bytesWritten, totalUnitCount: progress.totalBytes)
                    observer.onNext(taskProgress)
                default: break
                }
            }.disposed(by: bag)

        dataRequestObservable
            .flatMap { $0.rx.data() }
            .observeOn(observeScheduler)
            .subscribe(onNext: { [weak self] (data) in
                self?.data = data
            }, onError: { [weak self] (error) in
                observer.onError(error)
                self?.bag = nil
            }, onCompleted: { [weak self] in
                observer.onCompleted()
                self?.bag = nil
            })
            .disposed(by: bag)

        return subject.asObservable()
    }
}
