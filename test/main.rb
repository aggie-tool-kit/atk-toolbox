require_relative '../lib/atk_toolbox'

Dir.chdir __dir__

puts Info.paths.to_yaml

# only require the autocomplete, not the entire ATK toolbox
require File.dirname(Gem.find_latest_files('atk_toolbox')[0])+"/atk/autocomplete.rb"; Atk.autocomplete('_')