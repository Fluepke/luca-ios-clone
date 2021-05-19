import UIKit
import RxSwift
import JGProgressHUD

class DataAccessViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyStateView: UIView!

    private var progressHud = JGProgressHUD.lucaLoading()
    var dataAccesses: [(department: HealthDepartment, infos: [(traceInfo: TraceInfo, location: Location)])] = []
    var disposeBag: DisposeBag?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DataAccessHeaderView.self, forHeaderFooterViewReuseIdentifier: "DataAccessHeaderView")
    }

    func loadEntries() {
        let newDisposeBag = DisposeBag()
        self.progressHud.show(in: self.view)

        ServiceContainer.shared.accessedTraceIdRepo
            .restore()
            .asObservable()
            .flatMap { Observable.from($0) }
            .flatMap {
                AccessedTraceIdPairer.pairAccessedTraceProperties(accessedTraceId: $0)
            }.toArray()
            .map { dictsArray -> [HealthDepartment: [(TraceInfo, Location)]] in
                var retVal: [HealthDepartment: [(TraceInfo, Location)]] = [:]
                dictsArray.forEach { dict in
                    dict.forEach { entry in
                        retVal[entry.key] = entry.value
                    }
                }
                return retVal
            }.observe(on: MainScheduler.instance)
            .do(onSuccess: { dict in
                dict.isEmpty ? self.showEmptyState() : self.hideEmptyState()
                self.dataAccesses = Array(zip(dict.keys, dict.values))
                self.tableView.reloadData()
            }, onDispose: { self.progressHud.dismiss() })
            .subscribe()
            .disposed(by: newDisposeBag)
        disposeBag = newDisposeBag
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadEntries()
        self.navigationController?.setTranslucent()
        self.navigationController?.navigationBar.tintColor = .white
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disposeBag = nil
    }

    func showEmptyState() {
        emptyStateView.isHidden = false
        tableView.isHidden = true
    }

    func hideEmptyState() {
        emptyStateView.isHidden = true
        tableView.isHidden = false
    }

}
extension DataAccessViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataAccesses.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataAccesses[section].infos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "DataAccessTableViewCell", for: indexPath) as! DataAccessTableViewCell
        let dataAccess = dataAccesses[indexPath.section].infos[indexPath.row]

        cell.locationName.text = dataAccess.location.name
        let checkin = dataAccess.traceInfo.checkInDate
        if let checkout = dataAccess.traceInfo.checkOutDate {
            cell.dateLabel.text = "\(checkin.formattedDate) - \(checkout.formattedDate)"
        } else {
            cell.dateLabel.text = "\(checkin.formattedDate)"
        }

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // swiftlint:disable:next force_cast
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "DataAccessHeaderView") as! DataAccessHeaderView
        view.departmentLabel.text = dataAccesses[section].department.name

        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

}
