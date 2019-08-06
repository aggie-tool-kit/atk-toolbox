require 'atk_toolbox'
-"gem bump" or exit
-"gem build atk_toolbox.gemspec" or exit
require_relative './lib/atk_toolbox/version.rb'
-"gem push \"atk_toolbox-#{AtkToolbox::VERSION}.gem\"" or exit