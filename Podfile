platform :ios, '8.0'

target 'ChatCampUIKit' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  pod 'ChatCamp', '0.1.20'
  pod 'DKImagePickerController', '~> 4.0.0-beta'
  pod 'Alamofire'
  pod 'SwiftyCam'
  pod 'MBProgressHUD'

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == "SwiftyCam"
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '3.3'
            end
        end
    end
end
