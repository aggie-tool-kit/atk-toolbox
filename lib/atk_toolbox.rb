require 'ruby2_keywords'

# require all the ruby files
files = Dir.glob(File.join(__dir__, "atk", "**/*.rb"))
for each in files
    require_relative each
end