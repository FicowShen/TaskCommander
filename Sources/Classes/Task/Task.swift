import Foundation
import RxSwift

public struct TaskProgress: Equatable {
    public let completedUnitCount: Int64
    public let totalUnitCount: Int64

    public init(completedUnitCount: Int64, totalUnitCount: Int64) {
        self.completedUnitCount = completedUnitCount
        self.totalUnitCount = totalUnitCount
    }
}

public struct GroupTaskInfo: Equatable {
    public let successCount: Int
    public let failureCount: Int

    public init(successCount: Int, failureCount: Int) {
        self.successCount = successCount
        self.failureCount = failureCount
    }
}

public enum TaskState: CustomStringConvertible {
    case ready
    case working(_ progress: TaskProgress)
    case success
    case failure(_ error: Error)

    public var description: String {
        switch self {
        case .ready:
            return "ready"
        case .working:
            return "working"
        case .success:
            return "success"
        case .failure:
            return "failure"
        }
    }
}

public protocol TaskProtocol: class, Hashable {
    var id: String { get }
    var timeStamp: TimeInterval { get }
    var state: TaskState { get set }
    var observable: Observable<TaskState>? { get set }

    func start() -> Observable<TaskProgress>
}

open class Task: TaskProtocol {

    public static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id.hashValue)
    }

    public let id = UUID().uuidString
    public let timeStamp: TimeInterval = Date().timeIntervalSince1970

    public var state: TaskState = .ready
    public var observable: Observable<TaskState>?

    public init() { }

    open func start() -> Observable<TaskProgress> {
        fatalError("Implement your work in subclass.")
    }
}

public extension Collection where Self.Element: TaskProtocol {
    var groupObservable: Observable<GroupTaskInfo> {

        let subject = PublishSubject<GroupTaskInfo>()
        var disposables = [Disposable]()
        var successCount = 0
        var failureCount = 0

        func count(forState state: TaskState) {
            switch state {
            case .success:
                successCount += 1
            case .failure(_):
                failureCount += 1
            default:
                break
            }
            guard (successCount + failureCount) == self.count else { return }
            subject.onNext(GroupTaskInfo(successCount: successCount, failureCount: failureCount))
            subject.onCompleted()
        }

        self.forEach { (task) in
            guard let observable = task.observable else {
                // task has been finished
                count(forState: task.state)
                return
            }
            let disposable = observable
                .subscribe(onNext: { (state) in
                    count(forState: state)
                })
            disposables.append(disposable)
        }
        return subject.asObservable()
    }
}
