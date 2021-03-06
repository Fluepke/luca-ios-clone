import UIKit
import RxSwift
import JGProgressHUD
import Alamofire

class MainTabBarViewController: UITabBarController {

    private var disposeBag = DisposeBag()

    private var progressHud = JGProgressHUD.lucaLoading()

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self

        let borderView = UIView(frame: CGRect(x: 0, y: 0, width: tabBar.frame.size.width, height: 1))
        borderView.backgroundColor = .lucaGrey
        tabBar.addSubview(borderView)

        if let tabBarItems = tabBar.items {
            tabBarItems[0].title = L10n.Navigation.Tab.checkin
            tabBarItems[1].title = L10n.Navigation.Tab.health
            tabBarItems[2].title = L10n.Navigation.Tab.history
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let tabBarItems = tabBar.items {
            tabBar.selectionIndicatorImage = UIImage().createTabBarSelectionIndicator(tabSize: CGSize(width: tabBar.frame.width/CGFloat(tabBarItems.count), height: tabBar.frame.height))
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.selectedIndex = 1

        ServiceContainer.shared.userService.registerIfNeeded { result in
            if result == .userRecreated {
                ServiceContainer.shared.traceIdService.disposeData(clearTraceHistory: true)
            }
            DispatchQueue.main.async { self.progressHud.dismiss() }
        } failure: { (error) in
            DispatchQueue.main.async {
                self.progressHud.dismiss()
                let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error,
                                                        message: error.localizedDescription)
                self.present(alert, animated: true, completion: nil)
            }
        }

        subscribeToSelfCheckin()

        // Check accessed TraceIDs once in app runtime lifecycle
        ServiceContainer.shared.accessedTracesChecker
            .fetchAccessedTraceIds()
            .logError(self, "Accessed Trace Id check")
            .subscribe()
            .disposed(by: disposeBag)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didOpenDeeplink(_:)),
                                               name: CoronaTestDeeplinkService.deeplinkNotificationName,
                                               object: nil)
    }

    @objc func didOpenDeeplink(_ notification: Notification) {
        guard let testString = notification.userInfo!["test"] as? String else {
            return
        }

        let alert = AlertViewControllerFactory.createTestPrivacyConsent(confirmAction: {
            self.parseQRCode(testString: testString)
        })
        alert.modalTransitionStyle = .crossDissolve
        alert.modalPresentationStyle = .overCurrentContext
        present(alert, animated: true, completion: nil)
    }

    private func parseQRCode(testString: String) {
        ServiceContainer.shared.coronaTestProcessingService
            .parseQRCode(qr: testString)
            .subscribe(onError: { error in
                self.presentErrorAlert(for: error)
            })
            .disposed(by: disposeBag)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disposeBag = DisposeBag()
    }

    private func presentErrorAlert(for error: Error) {
        if let localizedError = error as? LocalizedTitledError {
            let alert = UIAlertController.infoAlert(title: localizedError.localizedTitle, message: localizedError.localizedDescription)
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController.infoAlert(title: L10n.Navigation.Basic.error, message: L10n.General.Failure.Unknown.message(error.localizedDescription))
            self.present(alert, animated: true, completion: nil)
        }
    }

    private func subscribeToSelfCheckin() {
        // Continuously check if there is any pending self check in request and consume it if its the case
        ServiceContainer.shared.selfCheckin
            .pendingSelfCheckinRx
            .flatMap { pendingCheckin -> Observable<(SelfCheckin, Bool)> in
                if let privateCheckin = pendingCheckin as? PrivateMeetingSelfCheckin {
                    return UIAlertController.okAndCancelAlertRx(viewController: self, title: L10n.Navigation.Basic.hint, message: L10n.Private.Meeting.Alert.description).map { (privateCheckin, $0) }
                }
                return Observable.of((pendingCheckin, true))
            }
            .filter { $0.1 }
            .flatMap { pendingCheckin in
                return Completable.from { ServiceContainer.shared.selfCheckin.consumeCurrent() }
                    .andThen(ServiceContainer.shared.traceIdService.checkInRx(selfCheckin: pendingCheckin.0))
                    .do(onSubscribe: { DispatchQueue.main.async { self.progressHud.show(in: self.view) } })
                    .do(onDispose: { DispatchQueue.main.async { self.progressHud.dismiss() } })
            }
            .ignoreElementsAsCompletable()
            .debug("Self checkin")
            .catch {
                self.rxErrorAlert(for: $0)
            }
            .logError(self, "Pending self checkin")
            .retry(delay: .seconds(1), scheduler: MainScheduler.instance)
            .subscribe()
            .disposed(by: disposeBag)

    }

    private func rxErrorAlert(for error: Error) -> Completable {
        UIAlertController.infoAlertRx(
            viewController: self,
            title: L10n.MainTabBarViewController.ScannerFailure.title,
            message: error.localizedDescription)
            .ignoreElementsAsCompletable()
            .andThen(Completable.error(error)) // Push the error through to retry the stream
    }
}

extension MainTabBarViewController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return viewController != tabBarController.selectedViewController
    }

}

extension MainTabBarViewController: UnsafeAddress, LogUtil {}
