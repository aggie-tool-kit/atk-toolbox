class String
    # example usage 
        # puts <<-HEREDOC.remove_indent
        #     This is a string
        #     this part is extra indented
        # HEREDOC
    def remove_indent
        gsub(/^[ \t]{#{self.match(/^[ \t]*/)[0].length}}/, '')
    end
end