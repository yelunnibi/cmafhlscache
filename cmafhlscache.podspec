#
# Be sure to run `pod lib lint cmafhlscache.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'cmafhlscache'
  s.version          = '0.1.2'
  s.summary          = 'cache cmaf and hls video on iOS'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "can cache cmaf and hls video, use GCDWeb and PinCache"

  s.homepage         = 'https://github.com/yelunnibi/cmafhlscache.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'applezy' => 'test@test.com' }
  s.source           = { :git => 'https://github.com/yelunnibi/cmafhlscache.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.platform          = :ios, '14.0'
  s.ios.deployment_target = '14.0'

  s.source_files = 'cmafhlscache/Classes/**/*'
  
  # s.resource_bundles = {
  #   'cmafhlscache' => ['cmafhlscache/Assets/*.png']
  # }
  s.dependency 'GCDWebServer', '~> 3.5.4'
  s.dependency 'PINCache', '~> 3.0'
end
