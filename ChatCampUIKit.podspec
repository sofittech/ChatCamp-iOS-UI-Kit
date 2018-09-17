Pod::Spec.new do |s|

s.platform = :ios
s.ios.deployment_target = '10.0'
s.name = "ChatCampUIKit"
s.summary = "ChatCamp iOS UI Kit"
s.description  = "UI Kit for ChatCamp iOS SDK"
s.requires_arc = true
s.version = "0.1.4"
s.license = { :type => "MIT", :file => "LICENSE" }
s.authors = {"Saurabh Gupta" => "saurabh.gupta@iflylabs.com", "Shashwat Srivastava"=>"shashwat@iflylabs.com", "Shubham Gupta"=>"shubham@iflylabs.com"}
s.homepage = "https://chatcamp.io"
s.source = { :git => "https://github.com/ChatCamp/ChatCamp-iOS-UI-Kit.git", :tag => "v#{s.version}"}

s.ios.frameworks = ["AVKit", "Photos", "AVFoundation", "MobileCoreServices", "SafariServices", "MapKit", "UIKit", "Foundation"]
s.dependency 'ChatCamp', '~> 0.1.20'
s.dependency 'DKImagePickerController', '~> 4.0.0-beta'
s.dependency 'Alamofire'
s.dependency 'SwiftyCam'
s.dependency 'MBProgressHUD', '~> 1.1.0'


s.source_files = "ChatCampUIKit/**/*.{swift}"
s.resources = "ChatCampUIKit/**/*.{png,jpeg,jpg,storyboard,xib}"
end
