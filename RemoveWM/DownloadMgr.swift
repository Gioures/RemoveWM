//
//  DownloadMgr.swift
//  FinishWaterMark
//
//  Created by Gioures on 2022/6/20.
//

import UIKit
import Alamofire
class DownloadMgr: NSObject {
    static let HOST = "http://tool.youfanzi.cn/T/duanjx/api.php?url="
    
    static func jiexi(urlSrt: String, completed:(@escaping (_ success: Bool, _ dic: [String:Any])->())){
        guard let url = URL(string: HOST + urlSrt) else {
            completed(false, ["def":"def"])
            return
        }
        Alamofire.request(url, method: .post,
                          parameters: nil,
                          encoding: JSONEncoding.default,
                          headers: nil).responseJSON { response in
            if response.result.isSuccess {
                print("\nresponse = \(response)\n")
                guard let dic = response.result.value as? [String: Any], let data = dic["data"] as? [String: Any] else {
                    completed(false, ["def":"def"])
                    return
                }
                completed(true, data)
            } else if response.result.isFailure {
                completed(false, ["def": "失败"]);
            }
            
        }
    }
    
}



@objc class BTFileDownloadApi: NSObject {
    
    typealias BT_FileDownloadProgress = (_ bytesRead:Int64,_ totalBytesRead:Int64,_ progrss:Double)->()
    typealias BT_FileDownloadSuccess = (_ reponse:Any)->()
    typealias BT_FileDownloadFail = (_ error:Error?)->()
    
    @objc var fileUrl:String = ""
    @objc var saveFilePath:String = "" // 文件下载保存的路径
    var cancelledData : Data?//用于停止下载时,保存已下载的部分
    var downloadRequest:DownloadRequest? //下载请求对象
    var destination:DownloadRequest.DownloadFileDestination!//下载文件的保存路径
    
    var progress:BT_FileDownloadProgress?
    var success:BT_FileDownloadSuccess?
    var fail:BT_FileDownloadFail?
    
    private var queue:DispatchQueue = DispatchQueue.main
    
    // 默认主线程
    @objc convenience init(fileUrl:String,saveFilePath:String,queue:DispatchQueue? = DispatchQueue.main,progress:BT_FileDownloadProgress?,success:BT_FileDownloadSuccess?, fail:BT_FileDownloadFail?) {
        
        self.init()
        self.fileUrl = fileUrl
        self.saveFilePath = saveFilePath
        self.success = success
        self.progress = progress
        self.fail = fail
        
        if queue != nil {
            self.queue = queue!
        }
        
        // 配置下载存储路径
        self.destination = {_,response in
            let saveUrl = URL(fileURLWithPath: saveFilePath)
            return (saveUrl,[.removePreviousFile, .createIntermediateDirectories] )
        }
        // 这里直接就开始下载了
        self.startDownloadFile()
    }
    
    // 暂停下载
    @objc func suspendDownload() {
        self.downloadRequest?.task?.suspend()
    }
    // 取消下载
    @objc func cancelDownload() {
        self.downloadRequest?.cancel()
        self.downloadRequest = nil;
        self.progress = nil
    }
    
    // 开始下载
    @objc func startDownloadFile() {
        if self.cancelledData != nil {
            
            self.downloadRequest = Alamofire.download(resumingWith: self.cancelledData!, to: self.destination)
            self.downloadRequest?.downloadProgress { [weak self] (pro) in
                guard let `self` = self else {return}
                DispatchQueue.main.async {
                    self.progress?(pro.completedUnitCount,pro.totalUnitCount,pro.fractionCompleted)
                }
            }
            self.downloadRequest?.responseData(queue: queue, completionHandler: downloadResponse)
            
        }else if self.downloadRequest != nil {
            self.downloadRequest?.task?.resume()
        }else {
            self.downloadRequest = Alamofire.download(fileUrl, to: self.destination)
            self.downloadRequest?.downloadProgress { [weak self] (pro) in
                guard let `self` = self else {return}
                DispatchQueue.main.async {
                    self.progress?(pro.completedUnitCount,pro.totalUnitCount,pro.fractionCompleted)
                }
            }
            
            self.downloadRequest?.responseData(queue: queue, completionHandler: downloadResponse)
        }
    }
    
    //根据下载状态处理
    private func downloadResponse(response:DownloadResponse<Data>){
        switch response.result {
        case .success:
            if let data = response.value, data.count > 1000 {
                print("下载完成")
                if self.success != nil{
                    DispatchQueue.main.async {
                        self.success?(response)
                    }
                }
            }else {
                try? FileManager.default.removeItem(atPath: saveFilePath)
                DispatchQueue.main.async {
                    self.fail?(NSError(domain: "文件下载失败", code: 12345, userInfo: nil) as Error)
                }
            }
        case .failure:
            self.cancelledData = response.resumeData//意外停止的话,把已下载的数据存储起来
            DispatchQueue.main.async {
                self.fail?(response.error)
            }
        }
    }
}
