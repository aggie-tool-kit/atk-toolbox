require_relative '../lib/atk/version.rb'
require_relative '../lib/atk/version.rb'
def bump
    version_filepath = "./lib/atk_toolbox/version.rb"
    version_text = IO.read(version_filepath)
    version_regex = /\d+\.\d+\.\d+/
    version_match = version_text.match(version_regex)
    version = Version.new(version_match[0])
    version.patch += 1
    version_text.sub!(version_regex, version.to_s)
    IO.write(version_filepath, version_text)
    return version.to_s
end
version = bump()
for each in `which -a gem`.split(/\n/)
    system("'#{each}' build atk_toolbox.gemspec") or exit
    system("'#{each}' push \"atk_toolbox-#{version}.gem\"") or exit
    system("git add -A && git commit -m 'version bump' && git push")
    # install it
    system("'#{each}' install ./atk_toolbox-#{version}.gem")
end