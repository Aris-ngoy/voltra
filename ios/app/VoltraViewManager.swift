import React
import SwiftUI
import UIKit

@objc(VoltraViewManager)
class VoltraViewManager: RCTViewManager {
  override func view() -> UIView! {
    return VoltraRNView()
  }

  override var methodQueue: DispatchQueue! {
    return DispatchQueue.main
  }

  @objc
  override static func requiresMainQueueSetup() -> Bool {
    return true
  }
}

class VoltraRNView: UIView {
  private var hostingController: UIHostingController<AnyView>?
  private var root: VoltraNode = .empty
  private var _viewId: String = UUID().uuidString

  override init(frame: CGRect) {
    super.init(frame: frame)
    clipsToBounds = true
    setupHostingController()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    clipsToBounds = true
    setupHostingController()
  }

  private func setupHostingController() {
    let view = Voltra(root: .empty, activityId: _viewId)
    let hostingController = UIHostingController(rootView: AnyView(view))
    hostingController.view.backgroundColor = .clear
    addSubview(hostingController.view)
    self.hostingController = hostingController
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    hostingController?.view.frame = bounds
  }

  @objc var viewId: String = "" {
    didSet {
      guard !viewId.isEmpty else { return }
      _viewId = viewId
      updateView()
    }
  }

  @objc var payload: String = "" {
    didSet {
      parseAndUpdatePayload(payload)
    }
  }

  private func parseAndUpdatePayload(_ jsonString: String) {
    do {
      let json = try JSONValue.parse(from: jsonString)
      root = VoltraNode.parse(from: json)
    } catch {
      print("Error setting payload in VoltraView: \(error)")
      root = .empty
    }

    updateView()
  }

  private func updateView() {
    hostingController?.view.removeFromSuperview()

    let newView = Voltra(root: root, activityId: _viewId)
    let newHostingController = UIHostingController(rootView: AnyView(newView))
    newHostingController.view.backgroundColor = .clear
    newHostingController.view.frame = bounds
    addSubview(newHostingController.view)

    hostingController = newHostingController
  }
}
