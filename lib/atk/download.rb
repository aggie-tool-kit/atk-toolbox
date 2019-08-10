require 'open-uri'
require 'fileutils'
require_relative './extra_file_utils'

def download(input_1=nil, from:nil, url:nil, as:nil)
    # argument checking 
        # if only one argument, either input_1 or url
        if ((input_1!=nil) != (url!=nil)) && (from==nil) && (as==nil)
            # this covers:
            #    download     'site.com/file'
            the_url = url || input_1
            file_name = the_url.match /(?<=\/)[^\/]+\z/ 
            file_name = file_name[0]
        elsif (as != nil) && ((input_1!=nil)!=(url!=nil))
            # this covers:
            #    download     'site.com/file' as:'file'
            #    download url:'site.com/file' as:'file'
            the_url = url || input_1
            file_name = as
        elsif ((from!=nil) != (url!=nil)) && input_1!=nil
            # this covers:
            #    download 'file' from:'site.com/file'
            #    download 'file'  url:'site.com/file'
            the_url = from || url
            file_name = input_1
        else
            message_ = "I'm not sure how you're using the download function.\n"
            message_ << "Please use one of the following methods:\n"
            message_ << "    download     'site.com/file'\n"
            message_ << "    download     'site.com/file', as:'file'\n"
            message_ << "    download url:'site.com/file', as:'file'\n"
            message_ << "    download 'file', from:'site.com/file'\n"
            message_ << "    download 'file',  url:'site.com/file'\n"
            raise message_
        end#if
    #end argument checking
    FileSys.write(open(URI.encode(the_url)).read, to: file_name)
end