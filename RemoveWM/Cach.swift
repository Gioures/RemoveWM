//
//  Cach.swift
//  RemoveWM
//
//  Created by Gioures on 2022/6/21.
//

import UIKit

class Cach: NSObject {
    func getCacheFileSize() -> String{
        var foldSize: UInt64 = 0
        let filePath: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
        if let files = FileManager.default.subpaths(atPath: filePath) {
            for path in files {
                let temPath: String = filePath+"/"+path
                let folder = try? FileManager.default.attributesOfItem(atPath: temPath) as NSDictionary
                if let c = folder?.fileSize() {
                    foldSize += c
                }
            }
        }
        //保留2位小数
        if foldSize > 1024*1024 {
            
            return String(format: "%.2f", Double(foldSize)/1024.0/1024.0) + "MB"
        }
        else if foldSize > 1024 {
            return String(format: "%.2f", Double(foldSize)/1024.0) + "KB"
        }else {
            return String(foldSize) + "B"
        }
    }
    
    static func getFileSizeByPath(path: String) -> String {
        var count: UInt64 = 0;
        let manager = FileManager.default
        if !manager.fileExists(atPath: path) {
            return "0.00M"
        }
        if let files = FileManager.default.subpaths(atPath: path) {
            for file in files {
                if let attributes = try? manager.attributesOfItem(atPath: path+file) { //结果为Dictionary类型
                    if let size = attributes[.size] as? UInt64 {
                        count = size + count
                    }
                }
            }
        }
        if count > 1024*1024 {
            return String(format: "%.2f", Double(count)/1024.0/1024.0) + "MB"
        }
        else if count > 1024 {
            return String(format: "%.2f", Double(count)/1024.0) + "KB"
        }else {
            return String(count) + "B"
        }
    }
    
    static func clearSomeCacher(withPath path: String) -> Bool{
        let manager = FileManager.default
        if !manager.fileExists(atPath: path) {
            return true
        }
        
        do {
            try manager.removeItem(atPath: path)
        } catch  {
            return false
        }
        
        do {
            try manager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return false
        }
        
        return true
//        ######（1）方法1：获取所有文件，然后遍历删除
//        let fileManager = FileManager.default
//        let myDirectory = NSHomeDirectory() + "/Documents/Files"
//        let fileArray = fileManager.subpaths(atPath: myDirectory)
//        for fn in fileArray!{
//            try! fileManager.removeItem(atPath: myDirectory + "/\(fn)")
//        }
//
//        ######（2）方法2：删除目录后重新创建该目录
//        let fileManager = FileManager.default
//        let myDirectory = NSHomeDirectory() + "/Documents/Files"
//        try! fileManager.removeItem(atPath: myDirectory)
//        try! fileManager.createDirectory(atPath: myDirectory, withIntermediateDirectories: true,
//                                         attributes: nil)


    }

}
