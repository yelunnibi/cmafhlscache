
import GCDWebServer
import PINCache

open class CMAFHLSCachingReverseProxyServer {
    static let originURLKey = "__hls_origin_url"
    
    private let webServer: GCDWebServer
    private let urlSession: URLSession
    private let cache: PINCaching
    
    private(set) var port: Int?
    
    public static var sharedInstance: CMAFHLSCachingReverseProxyServer?
    
    /// 启动配置
    public static func setUp() -> CMAFHLSCachingReverseProxyServer? {
        if sharedInstance != nil {
            return sharedInstance
        }
        sharedInstance = CMAFHLSCachingReverseProxyServer(webServer: GCDWebServer(), urlSession: URLSession.shared, cache: PINCache.shared)
        sharedInstance?.start(port: 8080)
        return sharedInstance
    }

  public init(webServer: GCDWebServer, urlSession: URLSession, cache: PINCaching) {
    self.webServer = webServer
    self.urlSession = urlSession
    self.cache = cache

    self.addRequestHandlers()
  }


  // MARK: Starting and Stopping Server

  open func start(port: UInt) {
    guard !self.webServer.isRunning else { return }
    self.port = Int(port)
    self.webServer.start(withPort: port, bonjourName: nil)
  }

  open func stop() {
    guard self.webServer.isRunning else { return }
    self.port = nil
    self.webServer.stop()
  }


  // MARK: Resource URL

  open func reverseProxyURL(from originURL: URL) -> URL? {
    guard let port = self.port else { return nil }

    guard var components = URLComponents(url: originURL, resolvingAgainstBaseURL: false) else { return nil }
    components.scheme = "http"
    components.host = "127.0.0.1"
    components.port = port

    let originURLQueryItem = URLQueryItem(name: Self.originURLKey, value: originURL.absoluteString)
    components.queryItems = (components.queryItems ?? []) + [originURLQueryItem]

    return components.url
  }


  // MARK: Request Handler

  private func addRequestHandlers() {
    self.addPlaylistHandler()
    self.addSegmentHandler()
  }

  private func addPlaylistHandler() {
    self.webServer.addHandler(forMethod: "GET", pathRegex: "^/.*\\.m3u8$", request: GCDWebServerRequest.self) { [weak self] request, completion in
      print("\n**CmafCache:-开始代理m3u8请求-\(request.url.absoluteString)")
      guard let self = self else {
        return completion(GCDWebServerDataResponse(statusCode: 500))
      }

      guard let originURL = self.originURL(from: request) else {
        return completion(GCDWebServerErrorResponse(statusCode: 400))
      }

      print("\n**CmafCache:-开始请求原始m3u8-\(originURL)")
      let task = self.urlSession.dataTask(with: originURL) { data, response, error in
        guard let data = data, let response = response else {
            print("\n**CmafCache:-请求原始m3u8失败-\(String(describing: error))")
          return completion(GCDWebServerErrorResponse(statusCode: 500))
        }

        let playlistData = self.reverseProxyPlaylist(with: data, forOriginURL: originURL)
        let contentType = response.mimeType ?? "application/x-mpegurl"
        completion(GCDWebServerDataResponse(data: playlistData, contentType: contentType))
      }

      task.resume()
    }
  }

  private func addSegmentHandler() {
    self.webServer.addHandler(forMethod: "GET", pathRegex: "^/.*\\.(ts|cmfa|cmfv)$", request: GCDWebServerRequest.self) { [weak self] request, completion in
        print("\n**CmafCache:-开始代理请求视频资源-\(request.url.absoluteString)-range=\(request.byteRange)")
      guard let self = self else {
          print("\n**CmafCache:= self == nil")
        return completion(GCDWebServerDataResponse(statusCode: 500))
      }

      guard let originURL = self.originURL(from: request) else {
          print("\n**CmafCache:= originalurl = nil")
        return completion(GCDWebServerErrorResponse(statusCode: 400))
      }
      
        print("\n**CmafCache:-开始请求原始视频资源-\(originURL)")
        var cachedKey = originURL
        var rangeKey = ""
        var urlRequest = URLRequest(url: originURL)
        if let range = request.headers["Range"] {
            urlRequest.setValue(range, forHTTPHeaderField: "Range")
            rangeKey = range
            print("\n**CmafCache:-开始请求原始视频资源-Range=\(rangeKey)")
        }
       
        /// 如果是cmfa的话， 要拼接key
        if rangeKey.isEmpty == false {
            if let cachedata = self.cachedDataKey(for: originURL.absoluteString + rangeKey) {
                print("\n**CmafCache: 查询到有缓存视频返回")
                return completion(GCDWebServerDataResponse(data: cachedata, contentType: "video/mp2t"))
            }
        } else {
            if let cachedData = self.cachedData(for: originURL) {
                print("\n**CmafCache: 查询到有缓存视频返回")
              return completion(GCDWebServerDataResponse(data: cachedData, contentType: "video/mp2t"))
            }
        }
    
     
        let task = self.urlSession.dataTask(with: urlRequest) { data, response, error in
            guard let data = data, let response = response else {
                print("\n**CmafCache:-请求原始视频资源失败-\(error)")
                return completion(GCDWebServerErrorResponse(statusCode: 500))
            }
            
            let contentType = response.mimeType ?? "video/mp2t"
            completion(GCDWebServerDataResponse(data: data, contentType: contentType))
            
            if(rangeKey.isEmpty == false) {
                print("\n**CmafCache:-请求成功 缓存资源")
                self.saveCacheDataKey(data, for: originURL.absoluteString + rangeKey)
            } else {
                print("\n**CmafCache:-请求成功 缓存资源")
                self.saveCacheData(data, for: originURL)
            }
        }
      task.resume()
    }
  }

  private func originURL(from request: GCDWebServerRequest) -> URL? {
    guard let encodedURLString = request.query?[Self.originURLKey] else { return nil }
    guard let urlString = encodedURLString.removingPercentEncoding else { return nil }
    let url = URL(string: urlString)
    return url
  }


  // MARK: Manipulating Playlist

    private func reverseProxyPlaylist(with data: Data, forOriginURL originURL: URL) -> Data {
        return String(data: data, encoding: .utf8)!
            .components(separatedBy: .newlines)
            .map { line in
                var resline = self.processPlaylistLine(line, forOriginURL: originURL)
                print("\n**CmafCache:-line=\(line)\n**CmafCache:-替换后=\(resline)")
                return resline
            }
            .joined(separator: "\n")
            .data(using: .utf8)!
    }

    /// 替换m3u8文件里面视频的下载地址
  private func processPlaylistLine(_ line: String, forOriginURL originURL: URL) -> String {
    guard !line.isEmpty else { return line }

    if line.hasPrefix("#") {
      return self.lineByReplacingURI(line: line, forOriginURL: originURL)
    }

    if let originalSegmentURL = self.absoluteURL(from: line, forOriginURL: originURL),
      let reverseProxyURL = self.reverseProxyURL(from: originalSegmentURL) {
      return reverseProxyURL.absoluteString
    }

    return line
  }

  private func lineByReplacingURI(line: String, forOriginURL originURL: URL) -> String {
      
      // 匹配 URI 部分的正则表达式
      let uriPattern = try! NSRegularExpression(pattern: #"URI="([^"]+)""#)
      let lineRange = NSMakeRange(0, line.count)
      guard let result = uriPattern.firstMatch(in: line, options: [], range: lineRange) else { return line }
      
      // 获取 URI
      let uri = (line as NSString).substring(with: result.range(at: 1))
      guard let absoluteURL = self.absoluteURL(from: uri, forOriginURL: originURL) else { return line }
      guard let reverseProxyURL = self.reverseProxyURL(from: absoluteURL) else { return line }
      
      // 构建替换后的字符串
      let replacedURI = "URI=\"\(reverseProxyURL.absoluteString)\""
      let replacedLine = (line as NSString).replacingCharacters(in: result.range, with: replacedURI)
      
      if line.contains("BYTERANGE") {
//          print("**CmafCache:-开始替换数据头了很重要-\(replacedLine)")
      }
      
      return replacedLine
  }

  private func absoluteURL(from line: String, forOriginURL originURL: URL) -> URL? {
    guard ["m3u8", "ts", "cmfa","cmfv"].contains(originURL.pathExtension) else { return nil }

    if line.hasPrefix("http://") || line.hasPrefix("https://") {
      return URL(string: line)
    }

    guard let scheme = originURL.scheme, let host = originURL.host else { return nil }

    let path: String
    if line.hasPrefix("/") {
      path = line
    } else {
      path = originURL.deletingLastPathComponent().appendingPathComponent(line).path
    }

    return URL(string: scheme + "://" + host + path)?.standardized
  }


  // MARK: Caching

    private func cachedData(for resourceURL: URL) -> Data? {
        let key = self.cacheKey(for: resourceURL)
        print("\n**CmafCache:查找缓存-key=\(key)")
        return self.cache.object(forKey: key) as? Data
    }
    
    private func cachedDataKey(for key: String) -> Data? {
        print("\n**CmafCache:查找缓存-key=\(key)")
        return self.cache.object(forKey: key) as? Data
    }
    
    private func saveCacheData(_ data: Data, for resourceURL: URL) {
        let key = self.cacheKey(for: resourceURL)
        print("\n**CmafCache:保存缓存-key=\(key)")
        self.cache.setObject(data, forKey: key)
    }
    
    private func saveCacheDataKey(_ data: Data, for resourceURLKey: String) {
        print("\n**CmafCache:保存缓存-key=\(resourceURLKey)")
        self.cache.setObject(data, forKey: resourceURLKey)
    }
    
    private func cacheKey(for resourceURL: URL) -> String {
        return resourceURL.absoluteString.data(using: .utf8)!.base64EncodedString()
    }
    
}
