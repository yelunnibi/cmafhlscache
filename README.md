# cmafhlscache

[![CI Status](https://img.shields.io/travis/applezy/cmafhlscache.svg?style=flat)](https://travis-ci.org/applezy/cmafhlscache)
[![Version](https://img.shields.io/cocoapods/v/cmafhlscache.svg?style=flat)](https://cocoapods.org/pods/cmafhlscache)
[![License](https://img.shields.io/cocoapods/l/cmafhlscache.svg?style=flat)](https://cocoapods.org/pods/cmafhlscache)
[![Platform](https://img.shields.io/cocoapods/p/cmafhlscache.svg?style=flat)](https://cocoapods.org/pods/cmafhlscache)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

appdelegate
```swift 
CMAFHLSCachingReverseProxyServer.setUp()
CMAFHLSCachingReverseProxyServer.sharedInstance?.start()
```

vc
```swift
        let reverseProxyURL = CMAFHLSCachingReverseProxyServer.sharedInstance?.reverseProxyURL(from: playlistURL)! ?? URL(string: "www.apple.com")
        let playerItem = AVPlayerItem(url: reverseProxyURL!)
        player = AVPlayer(playerItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds // 将视频画面填充到特定的UIView中
        view.layer.addSublayer(playerLayer)
        player.currentItem?.preferredForwardBufferDuration = 1
        player.play()
```



## Requirements

## Installation

cmafhlscache is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'cmafhlscache'
```

## Author

applezy, 19902075128@sohu.com

## License

cmafhlscache is available under the MIT license. See the LICENSE file for more info.
