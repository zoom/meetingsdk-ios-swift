//
//  Logger+AppLogger.swift
//  MobileRTCSwiftSample
//
//  Created by Zoom Communications on 4/17/26.
//  Copyright © Zoom Communications, Inc. All rights reserved.
//

import os

extension Logger {
    static let app = Logger(subsystem: "us.zoom.MobileRTCSwiftSample", category: "app")
    
    static func info(_ message: String?) {
        app.info("\(message ?? "nil")")
    }
    
    static func error(_ message: String?) {
        app.error("\(message ?? "nil")")
    }
    
    static func debug(_ message: String?) {
        app.debug("\(message ?? "nil")")
    }
    
    static func trace(_ message: String?) {
        app.trace("\(message ?? "nil")")
    }
    
    static func warning(_ message: String?) {
        app.warning("\(message ?? "nil")")
    }
    
    static func notice(_ message: String?) {
        app.notice("\(message ?? "nil")")
    }
    
    static func critical(_ message: String?) {
        app.critical("\(message ?? "nil")")
    }
    
    static func fault(_ message: String?) {
        app.fault("\(message ?? "nil")")
    }
}
