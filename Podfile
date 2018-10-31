source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/grigorye/podspecs.git'

platform :osx, '10.13'

project "URLHelperApp.xcodeproj"

pod 'GEContinuousIntegration', :git => 'https://github.com/grigorye/GEContinuousIntegration', :branch => 'master'
#pod 'GEContinuousIntegration', :path => '../GEContinuousIntegration'

###

$injected_pod_dir_as_xcconfig_vars = Hash.new

def inject_pod_dir_as_xcconfig_var(var_name, pod_name)
  $injected_pod_dir_as_xcconfig_vars[var_name] = pod_name
end

def post_install_inject_pod_dir_in_aggregate_xcconfig_var(installer, var_name, pod_name)
  sandbox = installer.sandbox

  installer.aggregate_targets.each do |target|
    pod_dir = sandbox.pod_dir(pod_name)
    path_in_xcconfig = sandbox.local_path_was_absolute?(pod_name) ? pod_dir : "#{target.relative_pods_root}/#{pod_dir.relative_path_from(Pathname.new(sandbox.root))}"
    target.xcconfigs.each do |config_name, xcconfig|
      xcconfig_path = target.user_project_path.dirname.join(target.xcconfig_relative_path(config_name))
      xcconfig_path.exist? && warn
      xcconfig.merge!(var_name => path_in_xcconfig)
      xcconfig.save_as(xcconfig_path)
    end
  end
end

###

target 'URLHelperApp' do
  use_frameworks!

  pod 'Then', '~> 2.4.0'
  pod 'Result', '~> 4.0.0'

  pod 'GEAppConfig/Core', :git => 'https://github.com/grigorye/GEAppConfig'
  pod 'GEAppConfig/Crashlytics', :git => 'https://github.com/grigorye/GEAppConfig'
  pod 'GEAppConfig/Answers', :git => 'https://github.com/grigorye/GEAppConfig'
  # pod 'GEAppConfig/Core', :path => '../GEAppConfig'
  # pod 'GEAppConfig/Crashlytics', :path => '../GEAppConfig'
  # pod 'GEAppConfig/Answers', :path => '../GEAppConfig'

  pod 'GETracing', :git => 'https://github.com/grigorye/GETracing'
  # pod 'GETracing', :path => '../GETracing'
  inject_pod_dir_as_xcconfig_var('GE_TRACING_POD_ROOT', 'GETracing')

  pod 'GEXcodeScripts', :git => 'https://github.com/grigorye/GEXcodeScripts'
  inject_pod_dir_as_xcconfig_var('GE_XCODE_SCRIPTS_POD_ROOT', 'GEXcodeScripts')

  pod 'GEXcodeBuildPhases', :git => 'https://github.com/grigorye/GEXcodeBuildPhases'
  # pod 'GEXcodeBuildPhases', :path => '../GEXcodeBuildPhases'
  inject_pod_dir_as_xcconfig_var('GE_XCODE_BUILD_PHASES_POD_ROOT', 'GEXcodeBuildPhases')
  script_phase :name => 'Integrate Fabric', :shell_path => '/bin/sh -e', :script => <<~END
    "${GE_XCODE_BUILD_PHASES:?}/IntegrateFabric"
  END
  script_phase :name => 'Embed Source Version into Bundle', :shell_path => '/bin/sh -e', :script => <<~END
    "${GE_XCODE_BUILD_PHASES:?}/EmbedSourceVersionIntoBundle"
  END

  target 'URLHelperAppTests' do
    inherit! :search_paths
  end

  target 'URLHelperAppUITests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  $injected_pod_dir_as_xcconfig_vars.each do |var_name, pod_name|
    post_install_inject_pod_dir_in_aggregate_xcconfig_var(installer, var_name, pod_name)
  end

  # Make -app.xcconfig included into the base configuration.
  installer.pods_project.targets.each do |target|
    if target.name == 'Pods-URLHelperApp'
      target.build_configurations.each do |configuration|
        xcconfig_path = configuration.base_configuration_reference.real_path
        xcconfig = Xcodeproj::Config.new(xcconfig_path)
        xcconfig.includes << '../../../URLHelperApp/URLHelperApp-app.xcconfig'
        xcconfig_path.exist? && warn
        xcconfig.save_as(xcconfig_path)
      end
    end
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      configuration.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.9'
      configuration.build_settings['OTHER_CFLAGS'] = '$(inherited) -Wno-comma'
      configuration.build_settings['CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF'] = 'NO'
    end
  end
end
