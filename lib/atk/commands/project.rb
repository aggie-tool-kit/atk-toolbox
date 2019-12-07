require_relative '../atk_info'

module ATK
    def self.project(args)
        # TODO: check to make sure project exists
        if args.length == 0
            puts "if you don't know how to use #{"project".blue} just run #{"project help".blue}"
            puts ""
            # if there are commands then show them
            begin
                commands = Info.project_commands
                if commands.is_a?(Hash) && commands.keys.size > 0
                    puts "commands for current project:"
                    puts `project commands`
                end
            rescue => exception
            end
        else
            # 
            # Check dependencies
            # 
                # if they're not met, then warn the user about that
                # check a hash of the file to see if anything has changed
            case args[0]
                when 'help', '--help', '-h'
                    puts <<-HEREDOC.remove_indent
                        #{"help".yellow}
                            #{"info:".green} displays the avalible tools
                            #{"examples:".green} #{'project help'.blue}
                        
                        #{"initialize".yellow}
                            #{"examples:".green}
                                #{'project init'.blue}
                                #{'project initialize'.blue}
                            #{"info:".green}
                                This will create an info.yaml in your current directory
                                The info.yaml will contain all the standard project managment tools
                                In the future this command will be more interactive

                        #{"synchronize".yellow}
                            #{"examples:".green}
                                #{'project sync'.blue}
                                #{'project synchronize'.blue}
                                #{'project synchronize --message=\'updated the readme\''.blue}
                            #{"info:".green}
                                Adds, commits, and then pulls/pushes all git changes
                                If there is merge conflict, it will show up as normal
                            #{"format:".green}
                                #{"project".blue} #{"synchronize".yellow} #{"<package>".cyan} #{"--message='your message'".light_magenta}
                        
                        #{"execute".yellow} 
                            #{"examples:".green}
                                #{'project execute compile'.blue}
                                #{'project exec compile'.blue}
                                #{'project exec main'.blue}
                                #{'project exec server'.blue}
                            #{"info:".green}
                                This will look at the info.yaml file in your project to find commands
                                You can use the `project init` command to generate an info.yaml which 
                                has example commands. Commands can be CMD/terminal/console commands, or ruby code.
                            #{"format:".green}
                                #{"project".blue} #{"execute".yellow} #{"<name-of-command>".cyan} #{"<arg1-for-command>".light_magenta} #{"<arg2-for-command>".light_magenta} #{"<...etc>".light_magenta}

                        #{"commands".yellow}
                            #{"examples:".green} #{'project commands'.blue}
                            #{"info:".green}
                                This will read the local info.yaml of your project to find commands
                                then it will list out each command with a short preview of the contents of that command
                    HEREDOC
                when 'initialize', 'init'
                    Info.init
                when 'synchronize', 'sync'
                    # if there is an argument
                    git_folder_path = FS.dirname(Info.source_path)/".git"
                    if not FS.is_folder(git_folder_path)
                        raise <<-HEREDOC.remove_indent
                            
                            
                            The `project sync` command was called inside of #{FS.dirname(Info.source_path)}
                            However, there doesn't seem to be a git repository in this folder
                            (and changes can't be saved/synced without a git repository)
                        HEREDOC
                    end
                    message = args[1]
                    if message == nil
                        message = ""
                    else
                        if not message.start_with?('--message=')
                            raise "\n\nWhen giving arguments to the sync command, please give your message as:\n\n    project sync --message='whatever you wanted to say'"
                        else
                            # remove the begining of the message
                            message = args[1].sub(/^--message=/,"")
                            # remove leading/trailing whitespace
                            message.strip!
                        end
                    end
                    if message.size == 0
                        message = '-'
                    end
                    
                    # add everything
                    system('git add -A')
                    # commit everything
                    system('git', 'commit', '-m', message)
                    # pull down everything
                    system('git pull --no-edit')
                    # push up everything
                    system('git push')
                    
                when 'mix'
                    not_yet_implemented()
                    structure_name = args[1]
                    # use this to mix a structure into the project
                    # TODO:
                    # get the context
                        # if there is a --context='something' command line option, then use that
                        # otherwise use the default(--context) speficied in the info.yaml
                        # re-iterate through the info.yaml (advanced_setup) keys
                        # find all of the "when(--context = 'something')" keys
                        # find the (dependencies) sub-key for them, create one if the key doesn't exist
                        # add the project and version to the 
                when 'add'
                    not_yet_implemented()
                    package = args[1]
                    # check if there is an info.yaml
                    # check if there is an local_package_manager in the info.yaml
                    # if there is only 1, then use it
                    # if there is more than one, ask which one the user wants to use
                when 'remove'
                    not_yet_implemented()
                    package = args[1]
                    # check if there is an local_package_manager in the info.yaml
                    # if it does use it to remove the package
                when 'execute', 'exec'
                    # extract the (project_commands) section from the info.yaml, 
                    # then find the command with the same name as args[1] and run it
                    # TODO: use https://github.com/piotrmurach/tty-markdown#ttymarkdown- to highlight the ruby code 
                    _, command_name, *command_args = args
                    command = Info.project_commands[command_name]
                    # temporairly set the dir to be the same as the info.yaml 
                    FS.in_dir(Info.folder()) do
                        if command.is_a?(String)
                            -(command+' '+command_args.join(' '))
                        elsif command.is_a?(Code)
                            command.run(*command_args)
                        elsif command == nil
                            puts "I don't think that command is in the info.yaml file"
                        end
                    end
                when 'commands'
                    max_number_of_chars_to_show = 80
                    commands = Info.project_commands
                    if commands.keys.size == 0
                        puts "0 avalible commands".cyan
                    else
                        for each_key, each_value in commands
                            puts "    #{each_key.to_s.yellow}: #{each_value.to_s.strip[0..max_number_of_chars_to_show].sub(/(.*)[\s\S]*/,'\1')}"
                        end
                    end
                else
                    puts "I don't recognized that command\nhere's the `project --help` which might get you what you're looking for:"
                    ATK.project(["help"])
            end
        end
    end
end