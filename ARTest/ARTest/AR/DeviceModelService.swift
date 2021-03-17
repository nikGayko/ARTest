//
//  DeviceModelService.swift
//  react-native-ar-glasses
//
//  Created by Mikita Haiko on 4/21/21.
//

import Foundation

enum Model {
    case iPodTouch5gen
    case iPodTouch6gen
    case iPodTouch7gen
    
    case iPhone4
    case iPhone4s
    case iPhone5
    case iPhone5c
    case iPhone5s
    case iPhone6
    case iPhone6Plus
    case iPhone6s
    case iPhone6sPlus
    case iPhoneSE
    case iPhone7
    case iPhone7Plus
    case iPhone8
    case iPhone8Plus
    case iPhoneX
    case iPhoneXS
    case iPhoneXSMax
    case iPhoneXR
    case iPhone11
    case iPhone11Pro
    case iPhone11ProMax
    case iPhoneSE2gen
    case iPhone12Mini
    case iPhone12
    case iPhone12Pro
    case iPhone12ProMax
    
    case iPad2
    case iPad3gen
    case iPad4gen
    case iPad5gen
    case iPad6gen
    case iPad7gen
    case iPad8gen
    
    case iPadAir
    case iPadAir2
    case iPadAir3gen
    case iPadAir4gen
    
    case iPadMini
    case iPadMini2
    case iPadMini3
    case iPadMini4
    case iPadMini5gen
    
    case iPadPro9_7inch
    case iPadPro10_5inch
    case iPadPro11inch1gen
    case iPadPro11inch2gen
    case iPadPro12_9inch1gen
    case iPadPro12_9inch2gen
    case iPadPro12_9inch3gen
    case iPadPro12_9inch4gen
    
    case unknown
}

extension Model {
    static let current: Model = {
        switch machineVersion {
        case "iPod5,1":                                 return .iPodTouch5gen
        case "iPod7,1":                                 return .iPodTouch6gen
        case "iPod9,1":                                 return .iPodTouch7gen
            
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return .iPhone4
        case "iPhone4,1":                               return .iPhone4s
        case "iPhone5,1", "iPhone5,2":                  return .iPhone5
        case "iPhone5,3", "iPhone5,4":                  return .iPhone5c
        case "iPhone6,1", "iPhone6,2":                  return .iPhone5s
        case "iPhone7,2":                               return .iPhone6
        case "iPhone7,1":                               return .iPhone6Plus
        case "iPhone8,1":                               return .iPhone6s
        case "iPhone8,2":                               return .iPhone6sPlus
        case "iPhone8,4":                               return .iPhoneSE
        case "iPhone9,1", "iPhone9,3":                  return .iPhone7
        case "iPhone9,2", "iPhone9,4":                  return .iPhone7Plus
        case "iPhone10,1", "iPhone10,4":                return .iPhone8
        case "iPhone10,2", "iPhone10,5":                return .iPhone8Plus
        case "iPhone10,3", "iPhone10,6":                return .iPhoneX
        case "iPhone11,2":                              return .iPhoneXS
        case "iPhone11,4", "iPhone11,6":                return .iPhoneXSMax
        case "iPhone11,8":                              return .iPhoneXR
        case "iPhone12,1":                              return .iPhone11
        case "iPhone12,3":                              return .iPhone11Pro
        case "iPhone12,5":                              return .iPhone11ProMax
        case "iPhone12,8":                              return .iPhoneSE2gen
        case "iPhone13,1":                              return .iPhone12Mini
        case "iPhone13,2":                              return .iPhone12
        case "iPhone13,3":                              return .iPhone12Pro
        case "iPhone13,4":                              return .iPhone12ProMax
            
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return .iPad2
        case "iPad3,1", "iPad3,2", "iPad3,3":           return .iPad3gen
        case "iPad3,4", "iPad3,5", "iPad3,6":           return .iPad4gen
        case "iPad6,11", "iPad6,12":                    return .iPad5gen
        case "iPad7,5", "iPad7,6":                      return .iPad6gen
        case "iPad7,11", "iPad7,12":                    return .iPad7gen
        case "iPad11,6", "iPad11,7":                    return .iPad8gen
        case "iPad4,1", "iPad4,2", "iPad4,3":           return .iPadAir
        case "iPad5,3", "iPad5,4":                      return .iPadAir2
        case "iPad11,3", "iPad11,4":                    return .iPadAir3gen
        case "iPad13,1", "iPad13,2":                    return .iPadAir4gen
        case "iPad2,5", "iPad2,6", "iPad2,7":           return .iPadMini
        case "iPad4,4", "iPad4,5", "iPad4,6":           return .iPadMini2
        case "iPad4,7", "iPad4,8", "iPad4,9":           return .iPadMini3
        case "iPad5,1", "iPad5,2":                      return .iPadMini4
        case "iPad11,1", "iPad11,2":                    return .iPadMini5gen
        case "iPad6,3", "iPad6,4":                      return .iPadPro9_7inch
        case "iPad7,3", "iPad7,4":                      return .iPadPro10_5inch
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return .iPadPro11inch1gen
        case "iPad8,9", "iPad8,10":                     return .iPadPro11inch2gen
        case "iPad6,7", "iPad6,8":                      return .iPadPro12_9inch1gen
        case "iPad7,1", "iPad7,2":                      return .iPadPro12_9inch2gen
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return .iPadPro12_9inch3gen
        case "iPad8,11", "iPad8,12":                    return .iPadPro12_9inch4gen
        default:                                        return .unknown
        }
    }()
    
    private static let machineVersion: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }()

}
