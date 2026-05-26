import Flutter
import UIKit

// MARK: - Host-app integration point
//
// The FaceLiveness / Amplify SPM packages cannot be imported from this
// CocoaPod target (they are linked to the Runner app target only). To work
// around that, the host app (Runner) implements `FaceLivenessViewProvider`
// and registers an instance in `FaceLivenessProviderRegistry.shared.provider`
// during application startup.

@objc public protocol FaceLivenessViewProvider {
    func attachFaceLivenessView(
        sessionId: String,
        region: String,
        toView container: UIView,
        onComplete: @escaping () -> Void,
        onError: @escaping (String) -> Void
    )
}

@objc public class FaceLivenessProviderRegistry: NSObject {
    @objc public static let shared = FaceLivenessProviderRegistry()
    @objc public var provider: FaceLivenessViewProvider?
    private override init() { super.init() }
}

class FaceLivenessView: NSObject, FlutterPlatformView {
    private var _view: UIView

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?,
        handler: EventStreamHadler
    ) {
        _view = UIView()
        super.init()
        createNativeView(view: _view, arguments: args, handler: handler)
    }

    func view() -> UIView { return _view }

    func createNativeView(view _view: UIView, arguments args: Any?, handler: EventStreamHadler) {
        guard let args = args as? [String: Any],
              let sessionId = args["sessionId"] as? String,
              let region = args["region"] as? String else {
            handler.onError(code: "invalidArgs")
            return
        }

        guard let provider = FaceLivenessProviderRegistry.shared.provider else {
            print("FaceLiveness: no provider registered in FaceLivenessProviderRegistry")
            handler.onError(code: "noProvider")
            return
        }

        provider.attachFaceLivenessView(
            sessionId: sessionId,
            region: region,
            toView: _view,
            onComplete: { handler.onComplete() },
            onError: { code in handler.onError(code: code) }
        )
    }
}
