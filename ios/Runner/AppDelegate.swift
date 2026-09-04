import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let sensitiveScreenShield = SensitiveScreenShield()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "SensitiveScreenProtection"
    )
    let channel = FlutterMethodChannel(
      name: "org.hanbova.hanbova/sensitive_screen",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setSensitiveScreen",
            let arguments = call.arguments as? [String: Any],
            let enabled = arguments["enabled"] as? Bool else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.sensitiveScreenShield.setEnabled(enabled)
      result(nil)
    }
  }
}

/// iOS does not offer an equivalent to Android's FLAG_SECURE. This shield
/// obscures the app switcher whenever recovery material is visible and while
/// system screen capture is active; it cannot prevent external capture.
private final class SensitiveScreenShield {
  private var isEnabled = false
  private var overlay: UIVisualEffectView?
  private var observers: [NSObjectProtocol] = []

  init() {
    let center = NotificationCenter.default
    observers = [
      center.addObserver(
        forName: UIApplication.willResignActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in self?.updateVisibility() },
      center.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in self?.updateVisibility() },
      center.addObserver(
        forName: UIScreen.capturedDidChangeNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in self?.updateVisibility() },
    ]
  }

  deinit {
    observers.forEach(NotificationCenter.default.removeObserver)
  }

  func setEnabled(_ enabled: Bool) {
    isEnabled = enabled
    updateVisibility()
  }

  private func updateVisibility() {
    let shouldObscure = isEnabled && (!isApplicationActive || UIScreen.main.isCaptured)
    guard shouldObscure else {
      overlay?.removeFromSuperview()
      overlay = nil
      return
    }
    guard overlay == nil, let window = activeWindow else { return }
    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
    blur.translatesAutoresizingMaskIntoConstraints = false
    blur.isAccessibilityElement = true
    blur.accessibilityLabel = "Sensitive wallet information hidden"
    window.addSubview(blur)
    NSLayoutConstraint.activate([
      blur.leadingAnchor.constraint(equalTo: window.leadingAnchor),
      blur.trailingAnchor.constraint(equalTo: window.trailingAnchor),
      blur.topAnchor.constraint(equalTo: window.topAnchor),
      blur.bottomAnchor.constraint(equalTo: window.bottomAnchor),
    ])
    overlay = blur
  }

  private var isApplicationActive: Bool {
    UIApplication.shared.applicationState == .active
  }

  private var activeWindow: UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)
  }
}
