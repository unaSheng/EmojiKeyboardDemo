//
//  DisplayLinkHandler.swift
//  Hertown
//
//  Created by li.wenxiu on 2024/7/15.
//

import Foundation
import UIKit
import Combine

extension CADisplayLink {
    
    private class DisplayLinkHandler: NSObject {
        private let handler: ((CADisplayLink) -> Void)
        
        init(_ handler: @escaping (CADisplayLink) -> Void) {
            self.handler = handler
        }
        
        @objc func handleDisplayLinkTick(_ sender: CADisplayLink) {
            self.handler(sender)
        }
    }
    
    class Canceller {
        private var cancellationHandler: (() -> Void)?
        fileprivate init(_ cancel: @escaping () -> Void) {
            self.cancellationHandler = cancel
        }
        func cancel() {
            self.cancellationHandler?()
            self.cancellationHandler = nil
        }
        deinit {
            self.cancel()
        }
    }
    
    static func add(to runLoop: RunLoop, in mode: RunLoop.Mode, preferredFramesPerSecond: Int? = nil, handler: @escaping (CADisplayLink) -> Void) -> Canceller {
        let displayLinkHandler = DisplayLinkHandler(handler)
        let displayLink = CADisplayLink(target: displayLinkHandler, selector: #selector(DisplayLinkHandler.handleDisplayLinkTick(_:)))
        if let preferredFramesPerSecond = preferredFramesPerSecond {
            displayLink.preferredFramesPerSecond = preferredFramesPerSecond
        }
        displayLink.add(to: runLoop, forMode: mode)
        return Canceller({
            displayLink.invalidate()
        })
    }
}

extension CADisplayLink.Canceller: Cancellable {
    
}

