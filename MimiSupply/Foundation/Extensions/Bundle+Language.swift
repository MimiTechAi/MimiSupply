//
//  Bundle+Language.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import Foundation

extension Bundle {
    private static var bundle: Bundle!
    
    public static func localizedBundle() -> Bundle! {
        if Bundle.bundle == nil {
            Bundle.bundle = Bundle.main
        }
        return Bundle.bundle
    }
    
    public static func setLanguage(_ language: String) {
        defer {
            object_setClass(Bundle.main, Bundle.self)
        }
        
        objc_setAssociatedObject(Bundle.main, &Bundle.bundle, Bundle.main, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        object_setClass(Bundle.main, Bundle.PrivateBundle.self)
        
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            Bundle.bundle = bundle
        } else {
            Bundle.bundle = Bundle.main
        }
    }
}

extension Bundle {
    class PrivateBundle: Bundle, @unchecked Sendable {
        override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
            return Bundle.localizedBundle().localizedString(forKey: key, value: value, table: tableName)
        }
    }
}