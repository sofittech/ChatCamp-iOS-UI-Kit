Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '10.0'
s.name = "ChatCampUIKit"
s.summary = "ChatCampUIKit - UIKit for Chat Camp iOS."
s.requires_arc = true

# 2
s.version = "0.1.3"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Saurabh Gupta" => "saurabh.gupta@iflylabs.com" }

# 5 - Replace this URL with your own Github page's URL (from the address bar)
s.homepage = "https://github.com/ChatCamp/ChatCamp-iOS-UI-Kit"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/ChatCamp/ChatCamp-iOS-UI-Kit.git", :tag => "#{s.version}"}

# 7
s.ios.frameworks = ["AVKit", "Photos", "AVFoundation", "MobileCoreServices", "SafariServices", "MapKit", "UIKit", "Foundation"]
s.dependency 'ChatCamp'
s.dependency 'DKImagePickerController', '~> 4.0.0-beta'
s.dependency 'Alamofire'
s.dependency 'SwiftyCam'
s.dependency 'MBProgressHUD'

# 8
s.source_files = "ChatCampUIKit/**/*.{swift}"

# 9
s.resources = "ChatCampUIKit/**/*.{png,jpeg,jpg,storyboard,xib}"
end
