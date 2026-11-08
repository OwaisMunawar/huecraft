@preconcurrency import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, @preconcurrency FlutterImplicitEngineDelegate {
  private var intelligence: HuecraftIntelligence?

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    intelligence = HuecraftIntelligence(messenger: engineBridge.applicationRegistrar.messenger())
  }
}
