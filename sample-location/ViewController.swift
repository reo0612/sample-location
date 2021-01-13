
import UIKit
import CoreLocation

class ViewController: UIViewController {
    // CLLocationManagerクラスのインスタンスlocationManagerをメンバプロパティとして宣言
    private var locationManager: CLLocationManager = {
        // インスタンスを初期化
        var locationManager = CLLocationManager()
        // 取得精度の設定(1km以内の精度)
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        // 位置情報取得間隔(5m移動したら位置情報取得)
        locationManager.distanceFilter = 5
        return locationManager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ユーザーに許可をリクエスト
        locationManager.requestWhenInUseAuthorization()
        // デリゲート先を自分のViewControllerにする
        locationManager.delegate = self
    }
    
    // 初回表示以外にもバックグラウンド復帰、タブ切り替えなどにも呼ばれるメソッド
    // まだビューが表示されていないため、計算コストの高い処理は避ける
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // iOSからの通知(UIApplication.willEnterForegroundNotification)を受信して登録されたメソッド(willEnterForeground)を呼び出す
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    // 画面が非表示になる直前に呼ばれるメソッド
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 常に監視されているクラス(アプリで共通、UserDefaultと同じ感じ)なので呼び出したら毎回、削除(バグが起こりやすいため)
        // 例えば、NavigationControllerを使ってViewController1 > 2 > 3に画面遷移し、全てのViewControllerでNotificationCenterを呼び、willEnterForegroundNotificationのメソッドを書いていたとする
        // 画面遷移したとしても、ViewController 1,2,3は消えない(メモリー上に残っている)ので
        // ViewController3の画面内でバックグラウンド復帰した場合、他のViewController1,2も反応してしまうため毎回、削除しなくてはならない
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    // バックグラウンド状態から戻ってきた時に呼ばれるメソッド(自分で作る)
    @objc private func willEnterForeground() {
        // バックグラウンド状態から戻ってきた時に位置情報サービスがオンの場合
        if CLLocationManager.locationServicesEnabled() {
            // アプリの現在の認証ステータス(非推奨 iOS 4.2–14.0)
            let status = CLLocationManager.authorizationStatus()
            
            switch status {
            // 許可しない場合
            case .denied:
                Alert.okAlert(vc: self, title: "アプリの位置情報サービスを\nオンにして下さい", message: "OKをタップすると設定アプリに移動します") { (_) in
                    // OKを選択した後、設定アプリに画面遷移する
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                }
                
            default:
                break
            }
        // バックグラウンド状態から戻ってきた時に位置情報サービスがオフの場合
        }else {
            Alert.okAlert(vc: self, title: "位置情報サービスを\nオンにして下さい", message: "「設定」アプリ ⇒「プライバシー」⇒「位置情報サービス」からオンにできます")
        }
    }
}

// ViewControllerにCLLocationManagerDelegateプロトコルを準拠
extension ViewController: CLLocationManagerDelegate {
    // CLLocationManagerクラスのインスタンス初期化および、認証ステータスが変更されたら呼ばれるメソッド(推奨 iOS14-)
    // バックグラウンド・フォアグラウンド関係なく認証ステータスが変更されたら呼ばれる
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            // 端末の位置情報サービスがオンの場合
            if CLLocationManager.locationServicesEnabled() {
                // アプリの現在の認証ステータス(推奨 iOS14-)
                let status = manager.authorizationStatus
                
                switch status {
                // 常に許可、Appの使用中は許可(一時的に許可も含まれる)
                case .authorizedAlways, .authorizedWhenInUse:
                    // 位置情報取得を開始
                    manager.startUpdatingLocation()
                
                // アプリが位置情報サービスを使用できるかどうかを選択していない場合
                case .notDetermined:
                    // ユーザーに許可をリクエスト
                    manager.requestWhenInUseAuthorization()
                    
                // 許可しない場合
                case .denied:
                    Alert.okAlert(vc: self, title: "アプリの位置情報サービスを\nオンにして下さい", message: "OKをタップすると設定アプリに移動します") { (_) in
                        // OKを選択した後、設定アプリに画面遷移する
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                    }
                // 何らかの制限があって認証ステータスを変更できない場合
                case .restricted:
                    Alert.okAlert(vc: self, title: "位置情報サービスの使用を\n許可されていません", message: "何らかの制限が掛かっています")
                    
                default:
                    break
                }
            // 端末の位置情報サービスがオフの場合
            }else {
                Alert.okAlert(vc: self, title: "位置情報サービスを\nオンにして下さい", message: "「設定」アプリ ⇒「プライバシー」⇒「位置情報サービス」からオンにできます")
            }
        }
    }
    
    // CLLocationManagerクラスのインスタンス初期化および、認証ステータスが変更されたら呼ばれるメソッド(非推奨 iOS 4.2–14.0)
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if CLLocationManager.locationServicesEnabled() {
            
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.startUpdatingLocation()
                
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
                
            case .denied:
                Alert.okAlert(vc: self, title: "アプリの位置情報サービスを\nオンにして下さい", message: "OKをタップすると設定アプリに移動します") { (_) in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                }
                
            case .restricted:
                Alert.okAlert(vc: self, title: "位置情報サービスの使用を\n許可されていません", message: "何らかの制限が掛かっています")
                
            default:
                break
            }
            
        }else {
            Alert.okAlert(vc: self, title: "位置情報サービスを\nオンにして下さい", message: "「設定」アプリ ⇒「プライバシー」⇒「位置情報サービス」からオンにできます")
        }
    }
    
    // 位置情報を取得・更新したら呼ばれるメソッド
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 位置情報を取得する
        guard let gps = manager.location?.coordinate else {
            // 取得出来なかったらアラートを表示したりなど
            return
        }
        // 位置情報の取得を停止する
        manager.stopUpdatingLocation()
        //経度と緯度を出力する
        let lat = gps.latitude
        let lng = gps.longitude
        print("経度：\(String(describing: lat)), 緯度：\(String(describing: lng))")
    }
    // 何らかの原因があって位置情報を取得できない場合に呼ばれるメソッド
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 本来なら、アラートで画面にエラー内容を表示したりする
        print("\((error as NSError).domain)")
    }
}
