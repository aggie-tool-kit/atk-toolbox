require_relative '../lib/atk_toolbox/version'
version = AtkToolbox::VERSION

# uninstall old gem versions
system "gem cleanup atk_toolbox"
system "gem uninstall atk_toolbox --version '#{version}'"
# generate the new gem
system "gem build atk_toolbox.gemspec"
# install it locally
system "gem install ./atk_toolbox-#{version}.gem"
