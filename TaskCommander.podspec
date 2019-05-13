#
# Be sure to run `pod lib lint TaskCommander.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TaskCommander'
  s.version          = '1.0.0'
  s.summary          = 'Managing tasks with RxSwift.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Manage your task by using RxSwift. And there are some predefined Task types. Such as general task, download task and upload task.
                       DESC

  s.homepage         = 'https://github.com/FicowShen/TaskCommander'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Ficow Shen' => 'ficow_shen@qq.com' }
  s.source           = { :git => 'https://github.com/FicowShen/TaskCommander.git', :tag => "#{s.version}" }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'TaskCommander/Classes/**/*'
  
  # s.resource_bundles = {
  #   'TaskCommander' => ['TaskCommander/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'

  s.dependency 'RxSwift', '~> 4.4.0'
  s.dependency 'Alamofire', '~> 4.8.1'
  s.dependency 'RxAlamofire', '~> 4.3.0'
end
