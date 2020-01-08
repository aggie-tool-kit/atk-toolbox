require_relative './lib/atk_toolbox/version'

Gem::Specification.new do |spec|
    spec.name              = "atk_toolbox"
    spec.version           = AtkToolbox::VERSION
    spec.date              = Time.now.strftime('%Y-%m-%d')
    spec.summary           = "The Ruby gem for all the standard tools ATK uses internally"
    spec.homepage          = "http://github.com//atk-toolbox"
    spec.email             = "jeff.hykin@gmail.com"
    spec.authors           = [ "Jeff Hykin" ]
    spec.has_rdoc          = false
    spec.license           = "CC-BY-ND-4.0"
    spec.add_runtime_dependency 'tty-prompt', '~> 0.19.0', '>= 0.19.0'

    spec.require_paths = ['./lib']
    
    spec.files            += Dir.glob("lib/*")
    spec.files            += Dir.glob("lib/**/*")
    spec.files            += Dir.glob("bin/**/*")
    spec.files            += Dir.glob("man/**/*")
    spec.files            += Dir.glob("test/**/*")
    
    # bin files
    for each in Dir.glob("bin/*")
        system "chmod a+x '#{each}'"
        spec.executables << File.basename(each)
    end
    
    spec.description       = <<-desc
    desc
end
