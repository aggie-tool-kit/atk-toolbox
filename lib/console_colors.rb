class String
    style_wrap = ->(name, number) do
        # reset: \\e\\[0m
        # some number of resets: (?:\\e\\[0m)+
        # any ansi style/color: \\e\\[([;0-9]+)m
        # some number of ansi-style/colors: ((?:\\e\\[([;0-9]+)m)*)
        eval(<<-HEREDOC)
            def #{name}()
                # fix nested
                self.gsub!(/(\\e\\[0m)(?:\\e\\[0m)*((?:\\e\\[([;0-9]+)m)*)/, '\\1\\2\e[#{number}m')
                # inject start
                self.sub!(/^((?:\\e\\[([;0-9]+)m)*)/, '\\1'+"\\e[#{number}m")
                # append reset
                self.replace("\#{self}\\e[0m")
            end
        HEREDOC
    end
    
    # 
    # generate foreground/background methods
    # 
    @@colors = {
        default: 39,
        black: 30,
        red: 31,
        green: 32,
        yellow: 33,
        blue: 34,
        magenta: 35,
        cyan: 36,
        white: 37,
        light_black: 90,
        light_red: 91,
        light_green: 92,
        light_yellow: 93,
        light_blue: 94,
        light_magenta: 95,
        light_cyan: 96,
        light_white: 97,
    }
    for each_key, each_value in @@colors
        # foreground
        style_wrap[each_key, each_value]
        # background
        style_wrap["on_#{each_key}", each_value+10]
    end
    
    # 
    # generate style methods
    # 
    styles = {
        normal:     "21;22;23;24;25;27;28;29", # reset all non-color changes
        bold:       1,
        dim:        2,
        italic:     3,
        underline:  4,
        blink:      5,
        flash:      6,
        invert:     7,
        hide:       8,
    }
    for each_key, each_value in styles
        style_wrap[each_key, each_value]
    end
    
    def unstyle
        self.gsub!(/\e\[([;0-9]+)m/,"")
    end
    
    def self.color_samples
        for background, foreground in @@colors.keys.permutation(2)
            eval("puts ' #{foreground} on_#{background} '.rjust(32).#{foreground}.on_#{background}")
        end
    end
end


# 
# Theme
#
class String
    def color_as(kind)
        case kind
            when :error
                self.white.on_red
            when :code
                self.blue.on_light_black
            when :key_term
                self.yellow.on_black
            when :title
                self.green.on_black
            when :argument, :message
                self.cyan.on_black
            when :optional
                self.light_magenta.on_black
            when :good
                self.green.on_black
            when :bad
                self.red.on_black
        end
    end
end