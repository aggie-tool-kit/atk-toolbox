# ADD_CURRENT_DIR="-v \"$PWD\":\"code\""
# TODO: run command needs to start in dir of code
# TODO: pick a standard volume name
# TODO: allow making dockerfile from anywhere


class DockerExecutable
    def create_from(name)
        docker_file_path = FS.pwd/'example.DockerFile'
        image_id = `$(docker build --network=host -f #{FS.basename(docker_file_path)} #{FS.dirname(docker_file_path)} | sub '[\s\S]*Successfully built (.+)' '\\1')`.chomp
        return image_id
    end
    
    def run(image_id)
        system "docker run -it -v #{FS.pwd}:/code #{image_id} /bin/bash"
    end
    
    def edit(image_id)
        
        # start a interactive detached run 
        container_id = `$(docker run -it -d --rm -v "$PWD":/code #{image_id} /bin/bash)`
        # put user into the already-running process, let the make whatever changes they want
        system "docker exec -it #{container_id} /bin/bash"
        # once they exit that, ask if they want to save those changes
        if Console.yes?("would you like to save those changes?")
            # save those changes to the container
            system "docker commit #{container_id} #{image_id}"
        end
        # kill the detached process (otherwise it will continue indefinitely)
        system "docker kill #{container_id}"
        system "docker stop #{container_id}"
        system "docker rm #{container_id}"
    end
    
    def export(image_id, to:nil)
        system "docker save -o #{to} #{image_id}"
    end
    
    def import(path)
        system "docker load -i #{path}"
    end
end