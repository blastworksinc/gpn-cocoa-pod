#
# Be sure to run `pod lib lint GPN.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "GPN"
  s.version          = "3.0.2"
  s.summary          = "GameHouse Promotion Network SDK."
  s.description      = <<-DESC
                       The GameHouse Promotion Network lets you drive app installs with intelligence and control. You can participate in GPN by integrating this open source SDK into your iOS apps. Also available for Android.
                       DESC
  s.homepage         = "http://partners.gamehouse.com/app-promotion-and-app-monetization/"
  s.license          = 'Apache License, Version 2.0'
  s.author           = { "GameHouse" => "gpn-support@realnetworks.com" }
  s.source           = { :git => "https://github.com/gamehouse/gpn-cocoa-pod.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/ghpartners'

  s.platform     = :ios, '5.0'

  s.subspec 'no-arc' do |ss1|
    ss1.source_files = 'Pod/Classes/External/GoogleToolboxforMac/**/*.{h,m,mm}'
    ss1.requires_arc = false
    ss1.compiler_flags = '-fno-objc-arc'
  end

  s.subspec 'arc' do |ss2|
    ss2.source_files = 'Pod/Classes/*.{h,m}', 'Pod/Classes/Implementation/**/*.{h,m,mm}', 'Pod/Classes/RemoteMonitor/**/*.{h,m,mm}'
    ss2.dependency "GPN/no-arc"
    ss2.requires_arc = true
  end

  s.public_header_files = 'Pod/Classes/*.h'
  s.frameworks = 'UIKit', 'Foundation', 'CoreGraphics', 'SystemConfiguration', 'CFNetwork', 'Security', 'CoreTelephony'
  s.weak_frameworks = 'StoreKit', 'AdSupport'
end
