# cmafhlscache

[![CI Status](https://img.shields.io/travis/applezy/cmafhlscache.svg?style=flat)](https://travis-ci.org/applezy/cmafhlscache)
[![Version](https://img.shields.io/cocoapods/v/cmafhlscache.svg?style=flat)](https://cocoapods.org/pods/cmafhlscache)
[![License](https://img.shields.io/cocoapods/l/cmafhlscache.svg?style=flat)](https://cocoapods.org/pods/cmafhlscache)
[![Platform](https://img.shields.io/cocoapods/p/cmafhlscache.svg?style=flat)](https://cocoapods.org/pods/cmafhlscache)

## 原理

可以缓存HLS CMAF格式视频，
原理如下：

![原理](https://user-images.githubusercontent.com/931655/69081879-45206a80-0a82-11ea-8fca-3c09f3b1ebb1.png)

1. **User** sets a reverse proxy url to the `AVPlayer` instead of the origin url.
    ```diff
    - https://example.com/vod.m3u8
    + http://127.0.0.1:8080/vod.m3u8?__hls_origin_url=https://example.com/vod.m3u8
    ```
2. **AVPlayer** requests a playlist(`.m3u8`) to the local reverse proxy server.
3. **Reverse proxy server** fetches the origin playlist and replaces all URIs to point the localhost.
    ```diff
      #EXTM3U
      #EXTINF:12.000,
    - vod_00001.ts
    + http://127.0.0.1:8080/vod.m3u8?__hls_origin_url=https://example.com/vod_00001.ts
      #EXTINF:12.000,
    - vod_00002.ts
    + http://127.0.0.1:8080/vod.m3u8?__hls_origin_url=https://example.com/vod_00002.ts
      #EXTINF:12.000,
    - vod_00003.ts
    + http://127.0.0.1:8080/vod.m3u8?__hls_origin_url=https://example.com/vod_00003.ts
    ```
4. **AVPlayer** requests segments(`.ts`) to the local reverse proxy server.
5. **Reverse proxy server** fetches the origin segment and caches it. Next time the server will return the cached data for the same segment.

## Usage

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
  pod 'cmafhlscache', :git => "https://github.com/yelunnibi/cmafhlscache.git", :branch => 'main'
```

## License

cmafhlscache is available under the MIT license. See the LICENSE file for more info.
