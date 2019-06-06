$LOAD_PATH.unshift 'lib'

Gem::Specification.new do |s|
  s.name              = "atk_toolbox"
  s.version           = "0.0.3"
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "The Ruby gem for all the standard tools ATK uses internally"
  s.homepage          = "http://github.com//atk-toolbox"
  s.email             = "jeff.hykin@gmail.com"
  s.authors           = [ "Jeff Hykin" ]
  s.has_rdoc          = false
  s.license           = "CC-BY-ND-4.0"
  
  s.files            += Dir.glob("lib/*")
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("bin/**/*")
  s.files            += Dir.glob("man/**/*")
  s.files            += Dir.glob("test/**/*")

#  s.executables       = %w( atk-toolbox )
  s.description       = <<desc
desc
end
