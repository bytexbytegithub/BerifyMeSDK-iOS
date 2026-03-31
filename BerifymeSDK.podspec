Pod::Spec.new do |s|
  s.name             = 'BerifymeSDK'
  s.version          = '1.2.0'
  s.summary          = 'Berify.me native iOS SDK for identity verification (KYC/IDV).'
  s.description      = <<-DESC
    Berify.me iOS Swift SDK provides phone verification, Incode/Clear WebView flows,
    biometrics, and native UI for onboarding and login.
  DESC
  s.homepage         = 'https://berify.me'
  s.license          = { :type => 'Copyright', :text => 'Copyright © Berify.me. All rights reserved.' }
  s.author           = { 'Berify.me' => 'support@berify.me' }

  s.source           = {
    :git => 'https://github.com/bytexbytegithub/BerifyMeSDK-iOS.git',
    :tag => s.version.to_s
  }

  s.ios.deployment_target = '13.0'
  s.swift_versions = '5.9'

  s.source_files = 'Sources/BerifymeSDK/**/*.swift'
  s.frameworks   = 'UIKit', 'Foundation', 'WebKit', 'LocalAuthentication', 'Security',
                   'AVFoundation', 'Photos', 'CoreLocation'

  s.requires_arc = true
  s.module_name  = 'BerifymeSDK'
end
