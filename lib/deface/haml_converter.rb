module Deface

  module HamlCompilerMethods
    def push_script(text, preserve_script, in_tag = false, preserve_tag = false,
                    escape_html = false, nuke_inner_whitespace = false)
      push_text "<%= #{text.strip} %>"

      if block_given?
        yield
        push_silent('end')
      end
    end

    def push_silent(text, can_suppress = false)
      push_text "<% #{text.strip} %>"
    end
  end

  module HamlParserMethods
    def parse_old_attributes(line)
      attributes_hash, rest, last_line = super(line)

      attributes_hash = "{#{deface_attributes(attributes_hash)}}"

      return attributes_hash, rest, last_line
    end


    def parse_new_attributes(line)
      attributes, rest, last_line = super(line)

      attributes[1] = deface_attributes(attributes[1])

      return attributes, rest, last_line
    end
    private
      # coverts { attributes into deface compatibily attributes
      def deface_attributes(attrs)
        return if attrs.nil?
        return attrs if attrs.scan(/\{/).count > 1

        attrs.gsub! /\{|\}/, ''

        attributes = {}
        scanner = StringScanner.new(attrs)
        scanner.scan(/\s+/)

        until scanner.eos?
          return unless key = scanner.scan(/:(\w*)|(["'])((?![\\#]|\2).|\\.)*\2|(\w*):/) #matches :key, 'key', "key" or key:
          return unless scanner.scan(/\s*(=>)?\s*/) #match => or just white space
          return unless value = scanner.scan(/(["'])((?![\\#]|\1).|\\.)*\1|[^\s,]*/) #match 'value', "value", value, @value, some-value
          return unless scanner.scan(/\s*(?:,|$)\s*/)
          attributes[key.to_s] = value
        end

        attrs = []
        attributes.each do |key, value|
          #only need to convert non-literal values
          if value[0] != ?' && value[0] != ?" && value[0] != ?:
            key = %Q{"data-erb-#{key.gsub(/:|'|"/,'')}"}
            value = %Q{"<%= #{value} %>"}
          end

          if key[-1] == ?:
            attrs << "#{key} #{value}"
          else
            attrs << "#{key} => #{value}"
          end
        end

        attrs.join(', ')
      end
  end

  class HamlConverter < Haml::Engine

    # spec coverage will always be bad on one-side
    # or the other of this if, travis-ci gemfile takes
    # care of 3.2 haml side for now (until 3.2 is relased)
    # then we should reverse to test 3.1 with gemfile
    #
    if Haml::VERSION >= "3.2"
      class Compiler < Haml::Compiler
        include HamlCompilerMethods
      end

      class Parser < Haml::Parser
        include HamlParserMethods
      end

      def initialize(template, options = {})
        options[:compiler_class] = Compiler
        options[:parser_class]   = Parser
        super(template, options)
      end
    else
      include HamlParserMethods
      include HamlCompilerMethods
    end

    def result
      Deface::Parser.undo_erb_markup! String.new(render)
    end
  end
end
