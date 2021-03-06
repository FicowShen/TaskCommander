import Foundation
import RxSwift

public final class TaskCommander<T: TaskProtocol> {

    public var maxWorkingTasksCount = 3

    private let subscribeScheduler: SchedulerType
    private let observeScheduler: SchedulerType

    private var taskObservers = [T: AnyObserver<TaskState>]()
    private var readyTasks = [T]()
    private var workingTasks = [T: DisposeBag]()
    private var finishedTasks = [T]()

    public var currentTasks: [T] {
        return workingTasks.keys + readyTasks + finishedTasks
    }

    public init(subscribeScheduler: SchedulerType = ConcurrentDispatchQueueScheduler(qos: .background), observeScheduler: SchedulerType = MainScheduler.instance) {
        self.subscribeScheduler = subscribeScheduler
        self.observeScheduler = observeScheduler
    }

    public func addTask(_ task: T) {
        let publishSubject = PublishSubject<TaskState>()
        task.observable = publishSubject.asObservable().share()
        saveTask(task, observer: publishSubject.asObserver())
    }

    public func addTasks(_ tasks: [T]) {
        tasks.forEach { addTask($0) }
    }

    private func saveTask(_ task: T, observer: AnyObserver<TaskState>) {
        readyTasks.append(task)
        taskObservers[task] = observer
        putReadyTasksIntoWorkingQueue()
    }

    private func putReadyTasksIntoWorkingQueue() {
        guard !readyTasks.isEmpty,
            workingTasks.count < maxWorkingTasksCount else { return }

        let toWorkCount = maxWorkingTasksCount - workingTasks.count
        let toWorkTasks = [T](readyTasks.prefix(toWorkCount))

        guard !toWorkTasks.isEmpty else { return }
        readyTasks.removeFirst(min(readyTasks.count, toWorkTasks.count))
        toWorkTasks.forEach { startWork($0) }

        if workingTasks.count < maxWorkingTasksCount {
            putReadyTasksIntoWorkingQueue()
        }
    }

    private func startWork(_ task: T) {
        guard let observer = taskObservers[task] else { return }

        let disposeBag = DisposeBag()
        workingTasks[task] = disposeBag

        task.start()
            .subscribeOn(subscribeScheduler)
            .observeOn(observeScheduler)
            .subscribe(onNext: { (progress) in
                task.state = .working(progress)
                observer.onNext(.working(progress))
            }, onError: { [weak self] (error) in
                task.state = .failure(error)
                observer.onNext(.failure(error))
                observer.onCompleted()
                task.observable = nil
                self?.taskFinished(task)
            }, onCompleted: { [weak self] in
                task.state = .success
                observer.onNext(.success)
                observer.onCompleted()
                task.observable = nil
                self?.taskFinished(task)
            })
            .disposed(by: disposeBag)

        task.state = .ready
        observer.onNext(.ready)
    }

    private func taskFinished(_ task: T) {
        workingTasks[task] = nil
        taskObservers[task] = nil
        finishedTasks.append(task)
        putReadyTasksIntoWorkingQueue()
    }
}
