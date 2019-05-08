module Deface
  module Applicator
    module ClassMethods
      # applies all applicable overrides to given source
      #
      def apply(source, details, log=true, syntax=:erb)
        overrides = find(details)

        if log && overrides.size > 0
          Rails.logger.debug "\e[1;32mDeface:\e[0m #{overrides.size} overrides found for '#{details[:virtual_path]}'"
        end

        unless overrides.empty?
          case syntax
          when :haml
            #convert haml to erb before parsing before
            source = Deface::HamlConverter.new(source).result
          when :slim
            source = Deface::SlimConverter.new(source).result
          end

          doc = Deface::Parser.convert(source)

          overrides.each do |override|
            if override.disabled?
              Rails.logger.debug("\e[1;32mDeface:\e[0m '#{override.name}' is disabled") if log
              next
            end

            override.parsed_document = doc
            matches = override.matcher.matches(doc, log)

            if log
              Rails.logger.send(matches.size == 0 ? :error : :debug, "\e[1;32mDeface:\e[0m '#{override.name}' matched #{matches.size} times with '#{override.selector}'")

              # temporarily check and notify on use of old selector styles.
              #
              if matches.empty? && override.selector.match(/code|erb-loud|erb-silent/)
                Rails.logger.error "\e[1;32mDeface: [WARNING]\e[0m Override '#{override.name}' may be using an invalid selector of '#{override.selector}', <code erb-loud|silent> tags are now <erb loud|silent>"
              end
            end

            if matches.empty?
              override.failure = "failed to match :#{override.action} selector '#{override.selector}'"
            else
              override.failure = nil
              matches.each {|match| override.execute_action match }
            end
          end

          #prevents any caching by rails in development mode
          details[:updated_at] = Time.now

          source = doc.to_s

          Deface::Parser.undo_erb_markup!(source)
        end

        source
      end
    end

    def execute_action(target_element)
      validate_original(target_element)
      create_action_command.execute(target_element)
    end

    def execute_action_on_range(target_range)
      create_action_command.execute_on_range(target_range)
    end

    def create_action_command
      commands = Rails.application.config.deface.actions
      command = commands.find { |command| command.to_sym == action }
      raise(DefaceError, "Action #{action} not found") unless command
      command.new(:source_element => safe_source_element, :attributes => attributes)
    end

    def compatible_with_end_selector?
      create_action_command.range_compatible?
    end

    def matcher
      if end_selector.blank?
        Deface::Matchers::Element.new(selector) # single css selector
      else
        unless compatible_with_end_selector?
          raise Deface::NotSupportedError, ":#{action} action does not support :closing_selector"
        end
        # targeting range of elements as end_selector is present
        Deface::Matchers::Range.new(name, selector, end_selector)
      end
    end
  end
end
