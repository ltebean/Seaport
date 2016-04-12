
Pod::Spec.new do |s|
  s.name         = "Seaport"
  s.version      = "0.2.0"
  s.summary      = "package management"
  s.homepage     = "https://github.com/ltebean/Seaport"
  s.license      = "MIT"
  s.author       = { "ltebean" => "yucong1118@gmail.com" }
  s.source       = { :git => "https://github.com/ltebean/Seaport.git", :tag => 'v0.2.0'}
  s.source_files = "Seaport/Sources/**/*"
  s.dependency "SSZipArchive"
  s.requires_arc = true
  s.platform     = :ios, '7.0'
end
