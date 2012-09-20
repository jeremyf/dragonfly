module Dragonfly
  module ImageMagick
    class Generator

      class Base
        def initialize(command_line=nil)
          @command_line = command_line || CommandLine.new
        end
        
        attr_reader :command_line
        
        def convert(args, format, tempfile=nil)
          command_line.convert(nil, args, format, tempfile)
        end
      end


      # PLAIN generator

      class Plain < Base
        def call(width, height, colour, opts={})
          format = opts[:format] || 'png'
          [
            convert("-size #{width}x#{height} xc:#{colour}", format),
            {:format => format.to_sym, :name => "plain.#{format}"}
          ]
        end
      end


      # PLASMA generator

      class Plasma < Base
        def call(width, height, format='png')
          [
            convert("-size #{width}x#{height} plasma:fractal", format),
            {:format => format.to_sym, :name => "plasma.#{format}"}
          ]
        end
      end


      # TEXT generator

      class Text < Base
        FONT_STYLES = {
          'normal'  => 'normal',
          'italic'  => 'italic',
          'oblique' => 'oblique'
        }

        FONT_STRETCHES = {
          'normal'          => 'normal',
          'semi-condensed'  => 'semi-condensed',
          'condensed'       => 'condensed',
          'extra-condensed' => 'extra-condensed',
          'ultra-condensed' => 'ultra-condensed',
          'semi-expanded'   => 'semi-expanded',
          'expanded'        => 'expanded',
          'extra-expanded'  => 'extra-expanded',
          'ultra-expanded'  => 'ultra-expanded'
        }

        FONT_WEIGHTS = {
          'normal'  => 'normal',
          'bold'    => 'bold',
          'bolder'  => 'bolder',
          'lighter' => 'lighter',
          '100'     => 100,
          '200'     => 200,
          '300'     => 300,
          '400'     => 400,
          '500'     => 500,
          '600'     => 600,
          '700'     => 700,
          '800'     => 800,
          '900'     => 900
        }

        def call(string, opts={})
          opts = HashWithCssStyleKeys[opts]
          args = []
          format = (opts[:format] || :png)
          background = opts[:background_color] || 'none'
          font_size = (opts[:font_size] || 12).to_i
          escaped_string = "\"#{string.gsub(/"/, '\"')}\""

          # Settings
          args.push("-gravity NorthWest")
          args.push("-antialias")
          args.push("-pointsize #{font_size}")
          args.push("-font \"#{opts[:font]}\"") if opts[:font]
          args.push("-family '#{opts[:font_family]}'") if opts[:font_family]
          args.push("-fill #{opts[:color]}") if opts[:color]
          args.push("-stroke #{opts[:stroke_color]}") if opts[:stroke_color]
          args.push("-style #{FONT_STYLES[opts[:font_style]]}") if opts[:font_style]
          args.push("-stretch #{FONT_STRETCHES[opts[:font_stretch]]}") if opts[:font_stretch]
          args.push("-weight #{FONT_WEIGHTS[opts[:font_weight]]}") if opts[:font_weight]
          args.push("-background #{background}")
          args.push("label:#{escaped_string}")

          # Padding
          pt, pr, pb, pl = parse_padding_string(opts[:padding]) if opts[:padding]
          padding_top    = (opts[:padding_top]    || pt || 0)
          padding_right  = (opts[:padding_right]  || pr || 0)
          padding_bottom = (opts[:padding_bottom] || pb || 0)
          padding_left   = (opts[:padding_left]   || pl || 0)

          tempfile = convert(args.join(' '), format)

          if (padding_top || padding_right || padding_bottom || padding_left)
            attrs  = command_line.identify(tempfile)
            text_width  = attrs[:width].to_i
            text_height = attrs[:height].to_i
            width  = padding_left + text_width  + padding_right
            height = padding_top  + text_height + padding_bottom

            args = args.slice(0, args.length - 2)
            args.push("-size #{width}x#{height}")
            args.push("xc:#{background}")
            args.push("-annotate 0x0+#{padding_left}+#{padding_top} #{escaped_string}")
            convert(args.join(' '), nil, tempfile)
          end

          [
            tempfile,
            {:format => format, :name => "text.#{format}"}
          ]
        end

        private

        # Use css-style padding declaration, i.e.
        # 10        (all sides)
        # 10 5      (top/bottom, left/right)
        # 10 5 10   (top, left/right, bottom)
        # 10 5 10 5 (top, right, bottom, left)
        def parse_padding_string(str)
          padding_parts = str.gsub('px','').split(/\s+/).map{|px| px.to_i}
          case padding_parts.size
          when 1
            p = padding_parts.first
            [p,p,p,p]
          when 2
            p,q = padding_parts
            [p,q,p,q]
          when 3
            p,q,r = padding_parts
            [p,q,r,q]
          when 4
            padding_parts
          else raise ArgumentError, "Couldn't parse padding string '#{str}' - should be a css-style string"
          end
        end
      end

    end
  end
end
