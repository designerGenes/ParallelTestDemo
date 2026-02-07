platform :ios, '18.0'

workspace 'Playground.xcworkspace'

target 'Playground' do
  use_frameworks!

  # Regular remote pod
  pod 'SwiftyJSON', '~> 5.0'

  # Local development pod
  pod 'GreetingKit', :path => './LocalPods/GreetingKit'
end

target 'PlaygroundUITests' do
  use_frameworks!
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '18.0'
    end
  end
end
