//
//  Collections.swift
//  FinishWaterMark
//
//  Created by Gioures on 2022/6/20.
//

import UIKit
import Photos
class Collections: NSObject {
    // 保存视频到系统相册
    static func writeToXiangce(path: String, completed:(@escaping (_ success: Bool, _ error: Error?) ->())){
        PHPhotoLibrary.shared().performChanges {
            let url = URL(fileURLWithPath: path)
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        } completionHandler: { success, error in
            completed(success, error);
        }
    }
}

