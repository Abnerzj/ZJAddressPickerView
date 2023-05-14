Pod::Spec.new do |s|
s.name         = "ZJAddressPickerView"
s.version      = "1.0.1"
s.summary      = "A fast, convenient view to show animation select address view."
s.description  = <<-DESC
A fast, convenient view to show animation select address view, similar to Taobao and JD address selection components.
DESC
s.homepage     = "https://github.com/Abnerzj/ZJAddressPickerView"
s.license      = { :type => "MIT", :file => "LICENSE" }
s.author             = { "Abnerzj" => "Abnerzj@163.com" }
s.social_media_url   = "http://weibo.com/ioszj"
s.platform     = :ios, "9.0"
s.source       = { :git => "https://github.com/Abnerzj/ZJAddressPickerView.git", :tag => s.version }
s.source_files  = "ZJAddressPickerView/*.{h,m}"
s.resources     = "ZJAddressPickerView/*.{bundle}"
s.requires_arc = true
end
