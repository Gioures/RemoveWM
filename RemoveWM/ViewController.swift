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

    @IBOutlet weak var play: UIButton!
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
        self.play.isHidden = true;
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
        hud.show(animated: true)
        // 下载并写入 相册
        let _ = BTFileDownloadApi(fileUrl: url, saveFilePath: path) { bytesRead, totalBytesRead, progrss in
            hud.progress = Float(progrss)
        } success: { reponse in
            hud.hide(animated: true)
            self.makeTheVideoPriver(path: path)
            Collections.writeToXiangce(path: path) {[weak self] success, error in
                DispatchQueue.main.async {
                    if success {
                        self?.view.makeToast("保存到相册成功")
                        self?.play.isHidden = false;
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
        DownloadMgr.jiexi(urlSrt: text) {[weak self] success ,datadic  in
            hud.hide(animated: true)
            if success {
                self?.model = JSONDeserializer<VideoModel>.deserializeFrom(dict: datadic)
                if self?.model != nil {
                    self?.view.makeToast("解析成功");
                }
            }else {
                self?.view.makeToast("解析失败");
            }
            
        }
    }
    
    @IBAction func playVideo(_ sender: UIButton) {
        guard let player = player.player else { return }
        player.play()
    }
    
    fileprivate func makeTheVideoPriver(path: String) {
        let url = URL(fileURLWithPath: path)
        let item = AVPlayerItem(url: url)
        player.player = AVPlayer(playerItem: item)
    }
    

}

