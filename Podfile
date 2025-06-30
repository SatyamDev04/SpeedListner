# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'SpeedListner' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SpeedListner

  
pod 'MBProgressHUD', '~> 1.2.0'
pod 'DeckTransition', '~> 2.0'
pod 'DropDown'
pod 'IQKeyboardManager'
pod 'Movin'
pod 'Stripe'
pod 'FittedSheets'
pod 'AlamofireImage'
pod 'NVActivityIndicatorView'
pod 'SwiftyJSON'
pod 'ReachabilitySwift'
pod 'Alamofire'
pod 'FBSDKLoginKit'
pod 'GoogleSignIn'
pod 'MarqueeLabel'
pod 'DeviceKit', '~> 1.3'
pod 'IDZSwiftCommonCrypto'
pod "Agrume"
pod 'SwiftyDropbox'
  target 'SpeedListnerTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'SpeedListnerUITests' do
    # Pods for testing
  end

end
post_install do |installer|
    installer.generated_projects.each do |project|
        project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
            end
        end
    end
end
