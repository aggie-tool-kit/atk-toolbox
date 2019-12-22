# 
# right before gem install
# 
pre_version = nil
Gem.pre_install do
    begin
        # if atk is already installed
        require 'atk_toolbox'
        pre_version = Atk.version
    rescue
    end
end

# 
# right after gem install
# 
Gem.post_install do
    post_version = Atk.version
    # download the latest
    temp_file = Atk.temp_path("update_handler.rb")
    FS.download("https://raw.githubusercontent.com/aggie-tool-kit/atk-toolbox/master/lib/after_gem_update.rb", to: temp_file)
    system(Atk.paths["ruby"], temp_file)
end