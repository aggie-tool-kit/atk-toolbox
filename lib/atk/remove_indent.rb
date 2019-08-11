class String
    # this is for having docstrings that get their indent removed
    # this is used frequently for multi-line strings and error messages
    # example usage 
    # puts <<-HEREDOC.remove_indent
    # This command does such and such.
    #     this part is extra indented
    # HEREDOC
    def remove_indent
        gsub(/^[ \t]{#{self.match(/^[ \t]*/)[0].length}}/, '')
    end
end