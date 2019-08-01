require_relative './lib/atk_toolbox/version'

Gem::Specification.new do |s|
  s.name              = "atk_toolbox"
  s.version           = AtkToolbox::VERSION
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "The Ruby gem for all the standard tools ATK uses internally"
  s.homepage          = "http://github.com//atk-toolbox"
  s.email             = "jeff.hykin@gmail.com"
  s.authors           = [ "Jeff Hykin" ]
  s.has_rdoc          = false
  s.license           = "CC-BY-ND-4.0"
  s.add_runtime_dependency 'zip', '~> 2.0', '>= 2.0.2'
  s.add_runtime_dependency 'git', '~> 1.5.0', '>= 1.5.0'
  s.add_runtime_dependency 'method_source', '~> 0.9.2', '>= 0.9.2'

  
  s.files            += Dir.glob("lib/*")
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("bin/**/*")
  s.files            += Dir.glob("man/**/*")
  s.files            += Dir.glob("test/**/*")

#  s.executables       = %w( atk-toolbox )
  s.description       = <<desc
desc
end
