Pod::Spec.new do |s|
  s.name         = "manticore-iosviewfactory"
  s.version      = "0.0.4"
  s.summary      = "manticore-iosviewfactory is a view controller factory pattern for creating iOS applications."
  s.description  = <<-DESC
          manticore-iosviewfactory is a view controller factory pattern for creating iOS applications.
          Designed with a two-level hierachical view controller structure. 
          Inspired by intents on the Android platform.
                    DESC
  s.homepage     = "https://github.com/rhfung/manticore-iosviewfactory"
  s.license      = 'MIT'
  s.author       = { "Richard Fung" => "richard@yetihq.com" }
  s.source       = { :git => "https://github.com/rhfung/manticore-iosviewfactory.git", :tag => "0.0.4" }
  s.platform     = :ios
  s.source_files = 'MCViewFactory/**/*.{h,m,xib}', 'public/*.h'
  s.resources    = 'MCViewFactory/**/*.xib'
  s.frameworks = 'QuartzCore', 'AVFoundation', 'UIKit', 'Foundation'
  s.requires_arc = true
  # s.dependency 'JSONKit', '~> 1.4'
end
