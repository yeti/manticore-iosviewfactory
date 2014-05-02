Pod::Spec.new do |s|
  s.name         = "MCViewFactory"
  s.version      = "0.0.9"
  s.summary      = "MCViewFactory is a view controller factory pattern for creating iOS applications, inspired from Android activity lifecycle."
  s.description  = <<-DESC
          Manticore iOS View Factory is a view controller factory pattern for creating iOS applications.
          Designed with a two-level hierachical view controller structure. 
          Inspired by Android activity lifecycle.
                    DESC
  s.homepage     = "https://github.com/YetiHQ/manticore-iosviewfactory"
  s.license      = 'MIT'
  s.authors       = { "Richard Fung" => "richard@yetihq.com", "Anthony Scherba" => "tony@yetihq.com" }
  s.source       = { :git => "https://github.com/YetiHQ/manticore-iosviewfactory.git", :tag => "0.0.9" }
  s.platform     = :ios
  s.source_files = '*.{h,m}'
  s.frameworks = 'QuartzCore', 'AVFoundation', 'UIKit', 'Foundation'
  s.requires_arc = true
  # s.dependency 'JSONKit', '~> 1.4'
end
