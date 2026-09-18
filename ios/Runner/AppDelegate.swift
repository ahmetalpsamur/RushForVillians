import Flutter
import UIKit
import UserNotifications
import CoreMotion
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var stepCounter: StepCountStreamHandler?
  private var launchAudioPlayer: AVAudioPlayer?
  private var rewardAudioPlayer: AVAudioPlayer?
  private var hasPlayedLaunchSound = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    GeneratedPluginRegistrant.register(with: self)
    registerStepSensorChannels()
    registerLaunchSoundChannel()
    if let controller = window?.rootViewController as? FlutterViewController {
      FlutterMethodChannel(name: "rush_for_villains/daily_notifications",
        binaryMessenger: controller.binaryMessenger).setMethodCallHandler { call, result in
        guard call.method == "configuration" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        result(["timeZone": TimeZone.current.identifier, "directory": directory.path])
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func registerLaunchSoundChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    FlutterMethodChannel(
      name: "rush_for_villains/launch_sound",
      binaryMessenger: controller.binaryMessenger
    ).setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "play":
        self?.playLaunchSound()
      case "playReward":
        self?.playRewardSound()
      default:
        result(FlutterMethodNotImplemented)
        return
      }
      result(nil)
    }
  }

  private func playRewardSound() {
    rewardAudioPlayer?.stop()
    rewardAudioPlayer = nil

    let assetKey = FlutterDartProject.lookupKey(
      forAsset: "lib/SoundEffects/GatherMusic.wav"
    )
    guard let path = Bundle.main.path(forResource: assetKey, ofType: nil) else {
      return
    }

    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.ambient, options: [.mixWithOthers])
      try session.setActive(true)
      let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
      player.numberOfLoops = 0
      player.prepareToPlay()
      rewardAudioPlayer = player
      player.play()
    } catch {
      rewardAudioPlayer = nil
    }
  }

  private func playLaunchSound() {
    guard !hasPlayedLaunchSound else { return }
    hasPlayedLaunchSound = true

    let assetKey = FlutterDartProject.lookupKey(
      forAsset: "lib/Start/anime_kiz_sesi.mp3"
    )
    guard let path = Bundle.main.path(forResource: assetKey, ofType: nil) else {
      return
    }

    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.ambient, options: [.mixWithOthers])
      try session.setActive(true)
      let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
      player.numberOfLoops = 0
      player.prepareToPlay()
      launchAudioPlayer = player
      player.play()
    } catch {
      launchAudioPlayer = nil
    }
  }

  /// Adım sayacı kanalları.
  ///
  /// `pedometer` paketi iOS'ta sayacı son cihaz açılışından başlatıyor.
  /// `CMPedometer` yalnızca 7 günlük geçmiş tuttuğu için uzun süre yeniden
  /// başlatılmamış bir cihazda o başlangıç noktası kayar ve değer oturumlar
  /// arasında düşebilir — sahte bir "sensör sıfırlandı" durumu üretir.
  ///
  /// Bu yüzden başlangıç anını Dart tarafı veriyor (son rapor anı). Okunan
  /// değer doğrudan "son rapordan beri atılan adım" olur; uygulama kapalıyken
  /// atılan adımlar da (geçmiş sorgusu) ilk olayda gelir.
  private func registerStepSensorChannels() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    let messenger = controller.binaryMessenger

    let handler = StepCountStreamHandler()
    stepCounter = handler
    FlutterEventChannel(name: "rush_for_villains/step_count", binaryMessenger: messenger)
      .setStreamHandler(handler)

    FlutterMethodChannel(name: "rush_for_villains/step_sensor", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        switch call.method {
        case "authorizationStatus":
          result(StepCountStreamHandler.authorizationStatus())
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }
}

/// `CMPedometer` akışını Flutter'a taşır.
///
/// Yayınlanan değer, `onListen` sırasında verilen `fromEpochMs` anından beri
/// atılan adım sayısıdır ve oturum boyunca yalnızca artar.
class StepCountStreamHandler: NSObject, FlutterStreamHandler {
  private let pedometer = CMPedometer()
  private var eventSink: FlutterEventSink?
  private var running = false

  static func authorizationStatus() -> String {
    guard CMPedometer.isStepCountingAvailable() else { return "unavailable" }
    switch CMPedometer.authorizationStatus() {
    case .authorized: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "notDetermined"
    @unknown default: return "unknown"
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events

    guard CMPedometer.isStepCountingAvailable() else {
      events(FlutterError(code: "unavailable",
                          message: "Bu cihazda adım sayacı yok.",
                          details: nil))
      return nil
    }
    if CMPedometer.authorizationStatus() == .denied
        || CMPedometer.authorizationStatus() == .restricted {
      events(FlutterError(code: "permission_denied",
                          message: "Hareket verisi izni verilmedi.",
                          details: nil))
      return nil
    }
    if running { return nil }
    running = true

    // Başlangıç anı Dart tarafından gelir; yoksa şimdi.
    var start = Date()
    if let args = arguments as? [String: Any],
       let fromEpochMs = args["fromEpochMs"] as? NSNumber {
      start = Date(timeIntervalSince1970: fromEpochMs.doubleValue / 1000.0)
    }
    // CMPedometer en fazla 7 günlük geçmiş tutar; daha eski bir başlangıç
    // sessizce kırpılır, o yüzden burada da sınırlanır.
    let earliest = Date().addingTimeInterval(-7 * 24 * 60 * 60)
    if start < earliest { start = earliest }

    pedometer.startUpdates(from: start) { [weak self] data, error in
      guard let self = self else { return }
      DispatchQueue.main.async {
        guard let sink = self.eventSink else { return }
        if error != nil {
          sink(FlutterError(code: "unknown",
                            message: error?.localizedDescription,
                            details: nil))
          return
        }
        guard let data = data else { return }
        sink(data.numberOfSteps.intValue)
      }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if running {
      pedometer.stopUpdates()
      running = false
    }
    eventSink = nil
    return nil
  }
}
