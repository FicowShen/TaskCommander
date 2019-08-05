#
# Be sure to run `pod lib lint TaskCommander.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TaskCommander'
  s.version          = '1.0.1'
  s.summary          = 'Managing tasks with RxSwift.'
  s.swift_version    = '5.0'

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
  s.author           = { 'Ficow Shen' => 'ficowshen@hotmail.com' }
  s.source           = { :git => 'https://github.com/FicowShen/TaskCommander.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'


  # DownloadTask & UploadTask

  s.subspec 'Core' do |core|
    core.source_files = 'Sources/Classes/Task/*.{h,m,swift}', 'Sources/Classes/TaskCommander/*.{h,m,swift}'
    core.dependency 'RxSwift', '~> 4.4.0'
  end

  s.subspec 'Tasks' do |tasks|
    tasks.source_files = 'Sources/Classes/TailoredTask/*.{h,m,swift}'
    tasks.exclude_files = 'Sources/Classes/Task/*.{h,m,swift}', 'Sources/Classes/TaskCommander/*.{h,m,swift}'
    tasks.dependency 'Alamofire', '~> 4.8.1'
    tasks.dependency 'RxAlamofire', '~> 4.3.0'
  end

end
