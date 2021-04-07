import Foundation

protocol DataRepoModel {
    
    /// If this value is nil, it will be autogenerated and appended to database
    /// If this value is not nil and there is no object with given ID, this object will be appended to database with given ID
    /// It this value is not nil and there is already an object with given ID, this will be overwritten
    var identifier: Int? { get set }
}

protocol DataRepoProtocol {
    associatedtype Model: DataRepoModel
    typealias ErrorCompletion = ((Error)->Void)
    
    /// Event name. Will be sent through NotificationCenter.
    var onDataChanged: String { get }
    
    func store(object: Model, completion: @escaping (Model)->Void, failure: @escaping ErrorCompletion)
    func store(objects: [Model], completion: @escaping ([Model])->Void, failure: @escaping ErrorCompletion)
    func restore(completion: @escaping ([Model])->Void, failure: @escaping ErrorCompletion)
    func remove(identifiers: [Int], completion: @escaping ()->Void, failure: @escaping ErrorCompletion)
    func removeAll(completion: @escaping ()->Void, failure: @escaping ErrorCompletion)
}
