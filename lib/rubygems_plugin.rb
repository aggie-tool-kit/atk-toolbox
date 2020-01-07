# NOTES:
# 
#    this is the ideal replacement for the "after_gem_update.rb"
#    however it (the ruby gem API) does not work as intended and has very *VERY* little documentation
#    there may be a way to get it working, however the name of this file and the following code are required
#    and finding their names in the ruby documentation is difficult (which is why dead code is living here)
#    the issue is something along the lines of:
#    - if gem 0.0.1 is already installed
#    - then gem install atk_toolbox (upgrading to atk_toolbox 0.0.2)
#    - will run the 0.0.1 version of this file instead of the 0.0.2 version
#    (even durning post_install)
#    I'm unsure of the initial behavior (aka assuming no atk_toolbox was installed)
#    this needs to be further tested/explored before replacing "after_gem_update.rb"


# # 
# # right before gem install
# # 
# pre_version = nil
# Gem.pre_install do
#     begin
#         # if atk is already installed
#         require 'atk_toolbox'
#         pre_version = Atk.version
#     rescue
#     end
# end

# # 
# # right after gem install
# # 
# Gem.post_install do
#     post_version = Atk.version
#     # download the latest
#     temp_file = Atk.temp_path("update_handler.rb")
#     FS.download("https://raw.githubusercontent.com/aggie-tool-kit/atk-toolbox/master/lib/after_gem_update.rb", to: temp_file)
#     system(Atk.paths["ruby"], temp_file)
# end