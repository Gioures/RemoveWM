//
//  Quanxian.swift
//  FinishWaterMark
//
//  Created by Gioures on 2022/6/20.
//

import UIKit
import Photos
let HOSTURL = "http://tool.youfanzi.cn/T/duanjx/api.php?url="
class Quanxian: NSObject {
    class func requestAccessPhotos(completed:()->()) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .notDetermined: break
            
        case .restricted: break
            
        case .denied: break
            
        case .authorized: break
            
        case .limited: break
            
        @unknown default: break
            
        }
    }
}

