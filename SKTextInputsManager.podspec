Pod::Spec.new do |s|

# 1
s.platform = :ios
s.swift_version = '4.0'
s.ios.deployment_target = '10.0'
s.name = "SKTextInputsManager"
s.summary = "TextInputsManager manages all text inputs in scrollview or view"
s.requires_arc = true

# 2
s.version = "0.0.7"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Serhii Kostian" => "skostyan666@gmail.com" }

# 5 - Replace this URL with your own Github page's URL (from the address bar)
s.homepage = "https://github.com/sjsoad/TextInputsManager"


# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/sjsoad/TextInputsManager.git", :tag => "#{s.version}"}

# 7
s.framework = "UIKit"

# 8
s.source_files = "TextInputsManager/**/*.{swift}"

end
