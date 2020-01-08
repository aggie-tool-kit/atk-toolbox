require_relative '../atk_info'

module Atk
    def self.project(args)
        # 
        # no arguments
        # 
        if args.length == 0
            begin
                info = Info.new 
            rescue Info::YamlFileDoesntExist => exception
                puts <<-HEREDOC.remove_indent
                    
                    It appears there is no #{"info.yaml".color_as :code} file
                    Meaning you're probably not in folder that contains a project
                    
                    To convert the current folder into a project folder run:
                        #{"project init".color_as :code}
                    
                    If you don't know how to use #{"project".color_as :code} just run #{"project help".color_as :code}
                HEREDOC
                exit
            end
            puts "If you don't know how to use #{"project".color_as :code} just run #{"project help".color_as :code}"
            puts ""
            # if there are commands then show them
            commands = info.commands
            if commands.is_a?(Hash) && commands.keys.size > 0
                puts "commands for current project:"
                puts `project commands`
            end
        else
            case args[0]
                # 
                # help
                # 
                when 'help', '--help', '-h'
                    puts <<-HEREDOC.remove_indent
                        #{"help".color_as :key_term}
                            #{"info:".color_as :title} displays the avalible tools
                            #{"examples:".color_as :title} #{'project help'.color_as :code}
                        
                        #{"initialize".color_as :key_term}
                            #{"examples:".color_as :title}
                                #{'project init'.color_as :code}
                                #{'project initialize'.color_as :code}
                            #{"info:".color_as :title}
                                This will create an info.yaml in your current directory
                                The info.yaml will contain all the standard project managment tools
                                In the future this command will be more interactive

                        #{"synchronize".color_as :key_term}
                            #{"examples:".color_as :title}
                                #{'project sync'.color_as :code}
                                #{'project synchronize'.color_as :code}
                                #{'project synchronize --message=\'updated the readme\''.color_as :code}
                            #{"info:".color_as :title}
                                Adds, commits, and then pulls/pushes all git changes
                                If there is merge conflict, it will show up as normal
                            #{"format:".color_as :title}
                                #{"project".color_as :code} #{"synchronize".color_as :key_term} #{"<package>".color_as :argument} #{"--message='your message'".color_as :optional}
                        
                        #{"execute".color_as :key_term} 
                            #{"examples:".color_as :title}
                                #{'project execute compile'.color_as :code}
                                #{'project exec compile'.color_as :code}
                                #{'project exec main'.color_as :code}
                                #{'project exec server'.color_as :code}
                            #{"info:".color_as :title}
                                This will look at the info.yaml file in your project to find commands
                                You can use the `project init` command to generate an info.yaml which 
                                has example commands. Commands can be CMD/terminal/console commands, or ruby code.
                            #{"format:".color_as :title}
                                #{"project".color_as :code} #{"execute".color_as :key_term} #{"<name-of-command>".color_as :argument} #{"<arg1-for-command>".color_as :optional} #{"<arg2-for-command>".color_as :optional} #{"<...etc>".color_as :optional}

                        #{"commands".color_as :key_term}
                            #{"examples:".color_as :title} #{'project commands'.color_as :code}
                            #{"info:".color_as :title}
                                This will read the local info.yaml of your project to find commands
                                then it will list out each command with a short preview of the contents of that command
                    HEREDOC
                # 
                # init
                # 
                when 'initialize', 'init'
                    Info.init
                # 
                # sync
                # 
                when 'synchronize', 'sync'
                    # if there is an argument
                    git_folder_path = FS.dirname(Info.path)/".git"
                    if not FS.is_folder(git_folder_path)
                        raise <<-HEREDOC.remove_indent
                            
                            
                            The `project sync` command was called inside of #{FS.dirname(Info.path)}
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
                # 
                # execute
                # 
                when 'execute', 'exec'
                    # extract the (project_commands) section from the info.yaml, 
                    # then find the command with the same name as args[1] and run it
                    # FUTURE: use https://github.com/piotrmurach/tty-markdown#ttymarkdown- to highlight the ruby code 
                    _, command_name, *command_args = args
                    command = Info.commands[command_name]
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
                # 
                # commands
                # 
                when 'commands'
                    max_number_of_chars_to_show = 80
                    commands = Info.commands
                    if commands.keys.size == 0
                        puts "0 avalible commands".color_as :message
                    else
                        for each_key, each_value in commands
                            puts "    #{each_key.to_s.color_as :key_term}: #{each_value.to_s.strip[0..max_number_of_chars_to_show].sub(/(.*)[\s\S]*/,'\1')}"
                        end
                    end
                # 
                # unrecognized
                # 
                else
                    puts "I don't recognized that command\nhere's the `project --help` which might get you what you're looking for:"
                    Atk.project(["help"])
            end
        end
    end
end