use_frameworks!

target 'TaskCommander_Example' do
  pod 'TaskCommander', :path => './'
  pod 'RxCocoa', '~> 4.4.0'

  target 'TaskCommander_Tests' do
    inherit! :search_paths
    
    pod 'RxTest'
    pod 'RxBlocking'
    
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Add Trace Resources flag to debug
      if target.name == 'RxSwift'
          target.build_configurations.each do |config|
              if config.name == 'Debug' || config.name == 'Beta'
                  config.build_settings['OTHER_SWIFT_FLAGS'] ||= ['-D', 'TRACE_RESOURCES']
              end
          end
      end
    end
  end
end
