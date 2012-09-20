module Dragonfly
  module ImageMagick

    # The ImageMagick Plugin does the following:
    # - registers an imagemagick analyser
    # - registers an imagemagick processor
    # - registers an imagemagick generator
    # - adds thumb shortcuts like '280x140!', etc.
    # Look at the source code for #call to see exactly how it configures the app.
    class Plugin

      def call(app)
        app.analyser.register(ImageMagick::Analyser, command_line)

        # Generators
        app.generators.add :plain, ImageMagick::Generator::Plain.new(command_line)
        app.generators.add :plasma, ImageMagick::Generator::Plasma.new(command_line)
        app.generators.add :text, ImageMagick::Generator::Text.new(command_line)

        # Processors
        app.processors.delegate_to(processor, [
          :resize,
          :auto_orient,
          :crop,
          :flip,
          :flop,
          :greyscale,
          :grayscale,
          :resize_and_crop,
          :rotate,
          :strip,
          :thumb
        ])
        app.processors.add :convert, Processor::Convert.new(command_line)
        app.processors.add :encode, Processor::Encode.new(command_line)

        app.configure do
          job :thumb do |geometry, format|
            process :thumb, geometry
            encode format if format
          end
          job :gif do
            encode :gif
          end
          job :jpg do
            encode :jpg
          end
          job :png do
            encode :png
          end
          job :convert do |args, format|
            process :convert, args, format
          end
          job :encode do |format, args|
            process :encode, format, args
          end
        end
      end

      def processor
        @processor ||= Processor.new(command_line)
      end

      def command_line
        @command_line ||= CommandLine.new
      end

      def convert_command(command)
        command_line.convert_command = command
      end

      def identify_command(command)
        command_line.identify_command = command
      end

    end
  end
end
