module ActionView
  class Template
    module Handlers
      class ERB
        class Erubi < ::Erubi::Engine
          def initialize(input, properties = {})
            @newline_pending = 0

            # Dup properties so that we don't modify argument
            properties = Hash[properties]
            properties[:preamble]   = "@output_buffer = output_buffer || ActionView::OutputBuffer.new;"
            properties[:postamble]  = "@output_buffer.to_s"
            properties[:bufvar]     = "@output_buffer"
            properties[:escapefunc] = ""

            super
          end
        end
      end
    end
  end
end
