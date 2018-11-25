Pod::Spec.new do |s|

  s.name = "URLHelperApp"
  s.version = "0.1"
  s.summary = "Internal pod for the app."

  s.description  = <<~END
    A pod containing just sources for now.
  END

  s.homepage = "https://github.com/grigorye/GEAppConfig"
  s.license = 'MIT'
  s.author = { "Grigory Entin" => "grigory.entin@gmail.com" }

  # s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.13'
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source = { :git => "https://github.com/grigorye/URLHelperApp.git" }
  
  s.resource_bundles = { 'URLHelperApp-Sources' => 'URLHelperApp' }

  s.static_framework = true

end
