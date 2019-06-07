# require all the ruby files
files = Dir.glob("atk/*.rb")
for each in files
    require_relative each
end