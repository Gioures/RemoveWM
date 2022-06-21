//
//  ViewController.swift
//  FinishWaterMark
//
//  Created by Gioures on 2022/6/19.
//

import UIKit
import Toast_Swift
import HandyJSON
import MBProgressHUD
import AVFoundation
import AVKit
class ViewController: UIViewController {

    @IBOutlet weak var clear: UIButton!
    @IBOutlet weak var displayView: UIView!
    @IBOutlet weak var save: UIButton!
    @IBOutlet weak var parsing: UIButton!
    @IBOutlet weak var textfield: UITextField!
    var model: VideoModel?
    lazy var player: AVPlayerViewController = {
        let p = AVPlayerViewController()
        p.player = AVPlayer()
        self.addChild(p)
        return p
    }()
    
    lazy var hostPath: String = {
        let duc = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        return duc! + "/去水印/"
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayView.addSubview(player.view)
        Quanxian.requestAccessPhotos {
            print("获取权限成功");
        }
        
        
        let str = NSAttributedString(string: "粘贴视频链接地址到此处", attributes: [.foregroundColor: UIColor.gray])
        textfield.attributedPlaceholder = str
        clear.setTitle(Cach.getFileSizeByPath(path: hostPath), for: .normal)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        player.view.frame = displayView.bounds;
    }

    // MARK: - 当前解析的视频的存储地址
    fileprivate func nowPath() -> String?{
        guard let url = model?.url else { return nil }
        let path = hostPath + url.md5 + ".MOV"
        return path
    }
    
    // MARK: - 保存视频
    @IBAction func saveVideo(_ sender: UIButton) {
        guard let url = model?.url else {
            view.makeToast("没有解析成功 请重新解析");
            return
        }
        
        if url.count == 0 {
            view.makeToast("没有解析成功 请重新解析");
            return
        }
        
        let path = nowPath()!
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.mode = .annularDeterminate
        hud.show(animated: true)
        // 下载并写入 相册
        let _ = BTFileDownloadApi(fileUrl: url, saveFilePath: path) { bytesRead, totalBytesRead, progrss in
            hud.progress = Float(progrss)
        } success: { reponse in
            hud.hide(animated: true)
            self.clear.setTitle(Cach.getFileSizeByPath(path: self.hostPath), for: .normal)
            Collections.writeToXiangce(path: path) {[weak self] success, error in
                DispatchQueue.main.async {
                    if success {
                        self?.view.makeToast("保存到相册成功")
                        self?.textfield.text = ""
                    }else {
                        self?.view.makeToast("保存到相册失败")
                    }
                }
            }
        } fail: { error in
            hud.hide(animated: true)
        }
    }
    
    @IBAction func parse(_ sender: UIButton) {
        guard let text = textfield.text else {
            view.makeToast("请填写解析地址")
            return
        }
        if text.count == 0 {
            view.makeToast("请填写解析地址")
            return
        }
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.show(animated: true)
        DownloadMgr.jiexi(urlSrt: self.getTheHttpText()) {[weak self] success ,datadic  in
            hud.hide(animated: true)
            if success {
                self?.model = JSONDeserializer<VideoModel>.deserializeFrom(dict: datadic)
                if self?.model != nil {
                    self?.view.makeToast("解析成功");
                    if let url = self?.model?.url {
                        self?.makeTheVideoPriver(path: url, bendi: false)
                    }
                }
            }else {
                self?.view.makeToast("解析失败");
            }
            
        }
    }
    
    
    @IBAction func clearCach(_ sender: UIButton) {
        let alert = UIAlertController(title: "提示", message: "确定删除缓存？", preferredStyle: .alert)
        let actionCertain = UIAlertAction(title: "确定", style: .default) { action in
            if Cach.clearSomeCacher(withPath: self.hostPath) {
                sender.setTitle("0.00MB", for: .normal)
            }
        }
        let actionCancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alert.addAction(actionCancel)
        alert.addAction(actionCertain)
        present(alert, animated: true, completion: nil)
    }
    
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

    
    
    fileprivate func makeTheVideoPriver(path: String, bendi: Bool = false) {
        var url: URL?
        if bendi {
            url = URL(fileURLWithPath: path)
        }else {
            url = URL(string: path)
        }
        
        guard let urlzz = url else {
            return
        }
        
        let item = AVPlayerItem(url: urlzz)
        player.player = AVPlayer(playerItem: item)
    }
    
    // MARK: - 获取简化后的链接
    private func getTheHttpText() -> String{
        guard let text = textfield.text else { return ""}
        if text.contains("复制此链接") {
            // 抖音
            let c = text.components(separatedBy: "http")
            if c.count == 2 {
                let str = c[1];
                let content = str.components(separatedBy: " 复制此链接")
                if content.count > 0 {
                    let httpsUrl = content[0]
                    return "http"+httpsUrl
                }
            }
        }
        return text
    }

}

