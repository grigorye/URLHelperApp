source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/grigorye/podspecs.git'

platform :osx, '10.10'

project "URLHelperApp.xcodeproj"

#pod 'GEContinuousIntegration', :git => 'https://github.com/grigorye/GEContinuousIntegration', :branch => 'master'
pod 'GEContinuousIntegration', :path => '../GEContinuousIntegration'

target 'URLHelperApp' do
  use_frameworks!

  target 'URLHelperAppTests' do
    inherit! :search_paths
  end

  target 'URLHelperAppUITests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      configuration.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.9'
      configuration.build_settings['OTHER_CFLAGS'] = '$(inherited) -Wno-comma'
      configuration.build_settings['CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF'] = 'NO'
    end
  end
end
