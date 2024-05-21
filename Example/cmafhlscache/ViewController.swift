//
//  ViewController.swift
//  cmafhlscache
//
//  Created by applezy on 05/20/2024.
//  Copyright (c) 2024 applezy. All rights reserved.
//

import UIKit
import cmafhlscache
import AVFoundation

class ViewController: UIViewController {
    var player : AVPlayer!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        let playlistURL = URL(string:"https://wd.gshortdramas.com/encode/sp/test/2ead7e26-3418-4008-9e8b-a71ff9be57ef.m3u8")!
                let playlistURL = URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")!
//        let playlistURL = URL(string: "https://dzf0mrmgw3o7o.cloudfront.net/videos/3/cmfa/2.m3u8")!
        
        let reverseProxyURL = CMAFHLSCachingReverseProxyServer.sharedInstance?.reverseProxyURL(from: playlistURL)! ?? URL(string: "www.apple.com")
        let playerItem = AVPlayerItem(url: reverseProxyURL!)
        player = AVPlayer(playerItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds // 将视频画面填充到特定的UIView中
        view.layer.addSublayer(playerLayer)
        player.currentItem?.preferredForwardBufferDuration = 5
        player.play()
    }
    
}

