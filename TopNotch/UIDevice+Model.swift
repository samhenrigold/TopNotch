//
//  UIDevice+Model.swift
//  TopNotch
//
//  Created by Sam Gold on 2025-02-10.
//

import UIKit

package extension UIDevice {
    /// The model identifier for the device (e.g., "iPhone14,4").
    static let modelIdentifier: String = {
        if let simulatorModelIdentifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulatorModelIdentifier
        }
        
        var sysinfo = utsname()
        uname(&sysinfo)
        
        let machineData = Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN))
        return String(bytes: machineData, encoding: .ascii)?.trimmingCharacters(in: .controlCharacters) ?? "unknown"
    }()
}
