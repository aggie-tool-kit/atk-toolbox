module Git
    def self.ensure_cloned_and_up_to_date(target_dir, git_repo_url)
        # check if it exists
        if FS.folder?(target_dir)
            # check if its a git repo
            if FS.folder?(target_dir/".git")
                # fetch master
                system("git fetch origin master")
                if $?.success?
                    # force pull
                    system("git reset --hard origin/master")
                end
                return
            else
                # clear the path
                FS.delete(target_dir)
            end
        end
        # clone the directory if pulling didn't occur
        system("git", "clone", git_repo_url, target_dir)
    end
    
    def self.repo_name(url)
        require_relative './file_system'
        *folders, name, extension = FS.path_pieces(url)
        return name
    end
end