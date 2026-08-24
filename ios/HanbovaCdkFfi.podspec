Pod::Spec.new do |s|
  s.name             = 'HanbovaCdkFfi'
  s.version          = '0.1.0'
  s.summary          = 'Hanbova CDK FFI Native Library for iOS'
  s.homepage         = 'https://hanbova.org'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Hanbova Team' => 'dev@hanbova.org' }
  s.source           = { :path => '.' }
  s.vendored_frameworks = 'Frameworks/HanbovaCdkFfi.xcframework'
  s.platform         = :ios, '13.0'
end
