Pod::Spec.new do |s|
s.name     = 'Unrar4iOS'
s.version  = '0.6'
s.license  = 'BSD & RAR'
s.summary  = 'Port of Unrar library to iOS and OS X platform'
s.homepage = 'https://github.com/augard/Unrar4iOS'
s.author   = { 'Vicent Scott' => 'vkan388@gmail.com' }
s.source   = { :git => 'https://github.com/augard/Unrar4iOS.git', :tag => "#{s.version}" }

s.description = 'The main goal of this project is provide a port of Unrar library to iOS platform.'

s.requires_arc   = false

s.preserve_paths = 'README*'

s.platform = :ios, :osx
s.ios.deployment_target = '5.0'
s.osx.deployment_target = '10.7'

s.library = 'c++', 'stdc++'
s.xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
    'CLANG_CXX_LIBRARY' => 'libc++'
}

s.public_header_files = 'Unrar4iOS/*.h'

s.source_files = 'Unrar4iOS/*.{h,m,mm}', 'Unrar4iOS/unrar/*.{hpp,cpp}'
s.compiler_flags = '-DSILENT', '-DRARDLL', '-Wno-dangling-else', '-Wno-undefined-inline', '-Wno-parentheses', '-Wno-return-type', '-Wno-unused-variable', '-Wno-switch'

end