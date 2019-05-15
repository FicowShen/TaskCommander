import Foundation
import RxSwift
import Alamofire
import RxAlamofire

public final class UploadTask: Task {

    public let request: URLRequest
    public let data: Data
    private var bag: DisposeBag?

    public init(request: URLRequest, data: Data) {
        self.request = request
        self.data = data
    }
    
    public override func start() -> Observable<TaskProgress> {
        let subject = PublishSubject<TaskProgress>()
        let observer = subject.asObserver()
        let bag = DisposeBag()
        self.bag = bag

        let observable = SessionManager.default.rx.upload(data, urlRequest: self.request)

        observable
            .flatMap { $0.rx.progress() }
            .observeOn(MainScheduler.instance)
            .subscribe { (event) in
                switch event {
                case .next(let progress):
                    guard progress.totalBytes != 0 else { return }
                    let taskProgress = TaskProgress(completedUnitCount: progress.bytesWritten, totalUnitCount: progress.totalBytes)
                    observer.onNext(taskProgress)
                case .error(let error):
                    observer.onError(error)
                case .completed:
                    break
                }
            }.disposed(by: bag)

        observable
            .flatMap { $0.rx.responseData() }
            .observeOn(MainScheduler.instance)
            .subscribe { (_) in
                observer.onCompleted()
            }.disposed(by: bag)

        return subject.asObservable()
    }
}
