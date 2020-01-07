require 'git'
require 'logger'

module Git
    def self.ensure_cloned_and_up_to_date(target_dir, git_repo_url)
        # check if it exists
        if FS.directory?(target_dir)
            if Console.verbose
                git_repo = Git.open(target_dir,  :log => Logger.new(STDOUT))
            else
                git_repo = Git.open(target_dir)
            end
        # if it doesn't exist, then clone it
        else
            git_repo = Git.clone(git_repo_url, target_dir)
        end
        # pull from origin master
        # TODO: make this a force pull
        git_repo.pull
    end
    
    def self.repo_name(url)
        require_relative './file_system'
        *folders, name, extension = FS.path_pieces(url)
        return name
    end
end