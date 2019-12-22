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
    require_relative './update_handler.rb'
    Atk.migrate(pre_version, post_version)
end