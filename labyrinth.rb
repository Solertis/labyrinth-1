# coding: utf-8

require_relative 'point2d'
require_relative 'direction'

class Labyrinth

    class ProgramError < Exception; end

    OPERATORS = {
        #' '  => ,
        '!'  => [:output_int],
        #'"'  => ,
        '#'  => [:nop],
        '$'  => [:depth],
        '%'  => [:mod],
        #'&'  => ,
        #'\'' => ,
        '('  => [:dec],
        ')'  => [:inc],
        '*'  => [:mul],
        '+'  => [:add],
        ','  => [:input_char],
        '-'  => [:sub],
        '.'  => [:output_char],
        '/'  => [:div],
        '0'  => [:digit, 0],
        '1'  => [:digit, 1],
        '2'  => [:digit, 2],
        '3'  => [:digit, 3],
        '4'  => [:digit, 4],
        '5'  => [:digit, 5],
        '6'  => [:digit, 6],
        '7'  => [:digit, 7],
        '8'  => [:digit, 8],
        '9'  => [:digit, 9],
        ':'  => [:dup],
        ';'  => [:pop],
        '<'  => [:rotate_west],
        '='  => [:swap_tops],
        '>'  => [:rotate_east],
        '?'  => [:input_int],
        '@'  => [:terminate],
        #'A'  => ,
        #'B'  => ,
        #'C'  => ,
        #'D'  => ,
        #'E'  => ,
        #'F'  => ,
        #'G'  => ,
        #'H'  => ,
        #'I'  => ,
        #'J'  => ,
        #'K'  => ,
        #'L'  => ,
        #'M'  => ,
        #'N'  => ,
        #'O'  => ,
        #'P'  => ,
        #'Q'  => ,
        #'R'  => ,
        #'S'  => ,
        #'T'  => ,
        #'U'  => ,
        #'V'  => ,
        #'W'  => ,
        #'X'  => ,
        #'Y'  => ,
        #'Z'  => ,
        #'['  => ,
        '\\'  => [:output_newline],
        #']'  => ,
        '^'  => [:rotate_north],
        '_'  => [:push_zero],
        #'`'  => ,
        #'a'  => ,
        #'b'  => ,
        #'c'  => ,
        #'d'  => ,
        #'e'  => ,
        #'f'  => ,
        #'g'  => ,
        #'h'  => ,
        #'i'  => ,
        #'j'  => ,
        #'k'  => ,
        #'l'  => ,
        #'m'  => ,
        #'n'  => ,
        #'o'  => ,
        #'p'  => ,
        #'q'  => ,
        #'r'  => ,
        #'s'  => ,
        #'t'  => ,
        #'u'  => ,
        'v'  => [:rotate_south],
        #'w'  => ,
        #'x'  => ,
        #'y'  => ,
        #'z'  => ,
        '{'  => [:move_to_main],
        #'|'  => ,
        '}'  => [:move_to_aux],
        '~'  => [:neg],
    }

    OPERATORS.default = [:wall]

    def self.run(src, debug_flag=false)
        new(src, debug_flag).run
    end

    def initialize(src, debug_flag=false)
        @debug = debug_flag

        @grid = parse(src)
        @height = @grid.size
        @width = @height == 0 ? 0 : @grid[0].size

        @ip = find_start
        @dir = East.new

        @main = []
        @aux = []

        @tick = 0
    end

    def run
        loop do
            puts "\nTick #{@tick}:" if @debug
            p @ip if @debug
            cmd = cell @ip
            p cmd if @debug
            if cmd[0] == :terminate
                break
            end
            process cmd
            puts @main*' ' + ' | ' + @aux*' ' if @debug
            @dir = get_new_dir
            p @dir if @debug
            @ip += @dir.vec

            @tick += 1
        end
    end

    private

    def parse(src)
        lines = src.split($/)

        grid = lines.map{|l| l.chars.map{|c| OPERATORS[c]}}

        width = grid.map(&:size).max

        grid.each{|l| l.fill([:wall], l.length...width)}
    end

    def find_start
        start = []
        @grid.each_with_index do |l,y|
            l.each_with_index do |c,x|
                if c[0] != :wall
                    start = Point2D.new(x,y)
                    break
                end
            end
            if start != []
                break
            end
        end

        start
    end

    def x
        @ip.x
    end

    def y
        @ip.y
    end

    def cell coords
        line = coords.y < 0 ? [] : @grid[coords.y] || []
        coords.x < 0 ? [:wall] : line[coords.x] || [:wall]
    end

    def push_main val
        @main << val
    end

    def push_aux val
        @aux << val
    end

    def pop_main
        @main.pop || 0
    end

    def pop_aux
        @aux.pop || 0
    end

    def peek_main
        @main[-1] || 0
    end

    def process cmd
        opcode, param = *cmd

        case opcode
        # Arithmetic
        when :push_zero
            push_main 0
        when :digit
            val = pop_main
            if val < 0
                push_main(val*10 - param)
            else
                push_main(val*10 + param)
            end
        when :inc
            push_main(pop_main+1)
        when :dec
            push_main(pop_main-1)
        when :add
            push_main(pop_main+pop_main)
        when :sub
            a = pop_main
            b = pop_main
            push_main(b-a)
        when :mul
            push_main(pop_main*pop_main)
        when :div
            a = pop_main
            b = pop_main
            push_main(b/a)
        when :mod
            a = pop_main
            b = pop_main
            push_main(b%a)
        when :neg
            push_main(-pop_main)

        # Stack manipulation
        when :dup
            push_main(peek_main)
        when :pop
            pop_main
        when :move_to_main
            push_main(pop_aux)
        when :move_to_aux
            push_aux(pop_main)
        when :swap_tops
            a = pop_aux
            m = pop_main
            push_aux m
            push_main a
        when :depth
            push_main(@main.size)

        # I/O
        when :input_char
            push_main(read_byte.ord)
        when :output_char
            $> << pop_main.chr
        when :input_int
            val = 0
            sign = 1
            byte = read_byte
            case byte
            when '+'
                sign = 1
            when '-'
                sign = -1
            else
                @next_byte = byte
            end

            loop do
                byte = read_byte
                if byte[/\d/]
                    val = val*10 + byte.to_i
                else
                    @next_byte = byte
                    break
                end
            end

            push_main(sign*val)
        when :output_int
            $> << pop_main
        when :output_newline
            puts

        # Grid manipulation
        when :rotate_west
            offset = pop_main
            @grid[(y+offset) % @height].rotate!(1)
            
            if offset == 0
                @ip += West.new.vec
                if x < 0
                    @ip.x = @width-1
                end
            end

            @grid.each{|l| p l} if @debug
        when :rotate_east
            offset = pop_main
            @grid[(y+offset) % @height].rotate!(-1)
            
            if offset == 0
                @ip += East.new.vec
                if x >= @width
                    @ip.x = 0
                end
            end

            @grid.each{|l| p l} if @debug
        when :rotate_north
            offset = pop_main
            grid = @grid.transpose
            grid[(x+offset) % @width].rotate!(1)
            @grid = grid.transpose
            
            if offset == 0
                @ip += North.new.vec
                if y < 0
                    @ip.y = @height-1
                end
            end

            @grid.each{|l| p l} if @debug
        when :rotate_south
            offset = pop_main
            grid = @grid.transpose
            grid[(x+offset) % @width].rotate!(-1)
            @grid = grid.transpose
            
            if offset == 0
                @ip += South.new.vec
                if y >= @height
                    @ip.y = 0
                end
            end

            @grid.each{|l| p l} if @debug

        # Others
        when :terminate
            raise '[BUG] Received :terminate. This shouldn\'t happen.'
        when :nop
            # Nop(e)
        end
    end

    def get_new_dir
        neighbors = []
        [North.new,
         East.new,
         South.new,
         West.new].each do |dir|
            neighbors << dir if cell(@ip + dir.vec)[0] != :wall
        end

        p neighbors if @debug

        case neighbors.size
        when 0
            # Remain where you are by moving back one step.
            # This can only happen at the start or due to shifting.
            @ip += @dir.reverse.vec
            @dir
        when 1
            # Move in the only possible direction
            neighbors[0]
        when 2
            neighbors = neighbors.select {|d| d.reverse != @dir}
            # If we came from one of the two directions, pick the other.
            # Otherwise, keep moving straight ahead (this can only happen
            # at the start or due to shifting).
            if neighbors.size == 2
                if neighbors.include? @dir
                    @dir
                else
                    neighbors.sample
                end
            else
                neighbors[0]
            end
        when 3
            val = peek_main
            if val < 0
                dir = @dir.left
            elsif val == 0
                dir = @dir
            else
                dir = @dir.right
            end
            if !neighbors.include? dir
                dir = dir.reverse
            end
            dir
        when 4
            val = peek_main
            if val < 0
                @dir.left
            elsif val == 0
                @dir
            else
                @dir.right
            end
        end
    end

    def read_byte
        result = nil
        if @next_byte
            result = @next_byte
            @next_byte = nil
        else
            result = STDIN.read(1)
        end
        result
    end
end

debug_flag = ARGV[0] == "-d"
if debug_flag
    ARGV.shift
end

Labyrinth.run(ARGF.read, debug_flag)