import Foundation
import RxSwift
import Alamofire
import RxAlamofire

public final class UploadTask: Task {

    public let request: URLRequest
    public let data: Data
    public let uploadRequestObservable: Observable<UploadRequest>

    private let observeScheduler: SchedulerType
    private var bag: DisposeBag?

    public init(request: URLRequest,
                data: Data,
                sessionManager: SessionManager = SessionManager.default,
                observeScheduler: SchedulerType = MainScheduler.instance) {
        self.request = request
        self.data = data
        self.observeScheduler = observeScheduler

        uploadRequestObservable = sessionManager.rx.upload(data, urlRequest: request)
    }

    public convenience init?(urlString: String,
                             data: Data,
                             sessionManager: SessionManager = SessionManager.default,
                             observeScheduler: SchedulerType = MainScheduler.instance) {
        guard let url = URL(string: urlString)
            else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        self.init(request: request,
                  data: data,
                  sessionManager: sessionManager,
                  observeScheduler: observeScheduler)
    }
    
    public override func start() -> Observable<TaskProgress> {
        let subject = PublishSubject<TaskProgress>()
        let observer = subject.asObserver()
        let bag = DisposeBag()
        self.bag = bag

        uploadRequestObservable
            .flatMap { $0.rx.progress() }
            .observeOn(observeScheduler)
            .subscribe { (event) in
                switch event {
                case .next(let progress):
                    guard progress.totalBytes > 0 else { return }
                    let taskProgress = TaskProgress(completedUnitCount: progress.bytesWritten, totalUnitCount: progress.totalBytes)
                    observer.onNext(taskProgress)
                case .error(let error):
                    observer.onError(error)
                case .completed: break
                }
            }.disposed(by: bag)

        uploadRequestObservable
            .flatMap { $0.rx.responseData() }
            .observeOn(observeScheduler)
            .subscribe { [weak self] (_) in
                observer.onCompleted()
                self?.bag = nil
            }.disposed(by: bag)

        return subject.asObservable()
    }
}
