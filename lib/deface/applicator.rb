module Deface
  module Applicator
    module ClassMethods
      # applies all applicable overrides to given source
      #
      def apply(source, details, log=true, haml=false)
        overrides = find(details)

        if log && overrides.size > 0
          Rails.logger.info "\e[1;32mDeface:\e[0m #{overrides.size} overrides found for '#{details[:virtual_path]}'"
        end

        unless overrides.empty?
          if haml
            #convert haml to erb before parsing before
            source = Deface::HamlConverter.new(source).result
          end

          doc = Deface::Parser.convert(source)

          overrides.each do |override|
            if override.disabled?
              Rails.logger.info("\e[1;32mDeface:\e[0m '#{override.name}' is disabled") if log
              next
            end

            override.parsed_document = doc

            if override.end_selector.blank?
              # single css selector

              matches = doc.css(override.selector)

              if log
                Rails.logger.send(matches.size == 0 ? :error : :info, "\e[1;32mDeface:\e[0m '#{override.name}' matched #{matches.size} times with '#{override.selector}'")
              end

              matches.each do |match|
                override.validate_original(match)

                case override.action
                  when :remove
                    match.replace ""
                  when :replace
                    match.replace override.source_element
                  when :replace_contents
                    match.children.remove
                    match.add_child(override.source_element)
                  when :surround
                    new_source = override.source_element.clone(1)
                    new_source.css("code:contains('render_original')").each do |original|
                      original.replace match.clone(1)
                    end
                    match.replace new_source
                  when :surround_contents
                    new_source = override.source_element.clone(1)
                    new_source.css("code:contains('render_original')").each do |original|
                      original.replace match.clone(1).children # Must clone match otherwise the children will only be assigned to first iteration.
                    end
                    match.children.remove
                    match.add_child new_source
                  when :insert_before
                    match.before override.source_element
                  when :insert_after
                    match.after override.source_element
                  when :insert_top
                    if match.children.size == 0
                      match.children = override.source_element
                    else
                      match.children.before(override.source_element)
                    end
                  when :insert_bottom
                    if match.children.size == 0
                      match.children = override.source_element
                    else
                      match.children.after(override.source_element)
                    end
                  when :set_attributes
                    override.attributes.each do |name, value|
                      name = normalize_attribute_name(name)

                      match.remove_attribute(name)
                      match.remove_attribute("data-erb-#{name}")

                      if match.attributes.key? name
                        match.set_attribute name, value.to_s
                      else
                        match.set_attribute "data-erb-#{name}", value.to_s
                      end
                    end
                  when :add_to_attributes
                    override.attributes.each do |name, value|
                      name = normalize_attribute_name(name)

                      if match.attributes.key? name
                        match.set_attribute name, match.attributes[name].value << " #{value}"
                      elsif match.attributes.key? "data-erb-#{name}"
                        match.set_attribute "data-erb-#{name}", match.attributes["data-erb-#{name}"].value << " #{value}"
                      else
                        match.set_attribute "data-erb-#{name}", value.to_s
                      end

                    end
                  when :remove_from_attributes
                    override.attributes.each do |name, value|
                      name = normalize_attribute_name(name)

                      if match.attributes.key? name
                        match.set_attribute name, match.attributes[name].value.gsub(value.to_s, '').strip
                      elsif match.attributes.key? "data-erb-#{name}"
                        match.set_attribute "data-erb-#{name}", match.attributes["data-erb-#{name}"].value.gsub(value.to_s, '').strip
                      end
                    end

                end

              end
            else
              unless [:remove, :replace, :replace_contents, :surround, :surround_contents].include? override.action
                raise Deface::NotSupportedError, ":#{override.action} action does not support :closing_selector"
              end
              # targeting range of elements as end_selector is present
              starting, ending = select_endpoints(doc, override.selector, override.end_selector)

              if starting && ending
                if log
                  Rails.logger.info("\e[1;32mDeface:\e[0m '#{override.name}' matched starting with '#{override.selector}' and ending with '#{override.end_selector}'")
                end

                elements = select_range(starting, ending)

                case override.action
                  when :remove
                    elements.map &:remove
                  when :replace
                    starting.before(override.source_element)
                    elements.map &:remove
                  when :replace_contents
                    elements[1..-2].map &:remove
                    starting.after(override.source_element)
                  when :surround, :surround_contents
                    new_source = override.source_element.clone(1)
                    new_source.css("code:contains('render_original')").each do |original|

                      if override.action == :surround
                        start = elements[0].clone(1)
                        original.replace start

                        elements[1..-1].each do |element|
                          element = element.clone(1)
                          start.after element
                          start = element
                        end

                        starting.before(new_source)
                        elements.map &:remove

                      elsif override.action == :surround_contents

                        start = elements[1].clone(1)
                        original.replace start

                        elements[2...-1].each do |element|
                          element = element.clone(1)
                          start.after element
                          start = element
                        end

                        starting.after(new_source)
                        elements[1...-1].map &:remove
                      end
                    end
                end
              else
                if starting.nil?
                  Rails.logger.info("\e[1;32mDeface:\e[0m '#{override.name}' failed to match with starting selector '#{override.selector}'")
                else
                  Rails.logger.info("\e[1;32mDeface:\e[0m '#{override.name}' failed to match with end selector '#{override.end_selector}'")
                end
              end
            end

          end

          #prevents any caching by rails in development mode
          details[:updated_at] = Time.now

          source = doc.to_s

          Deface::Parser.undo_erb_markup!(source)
        end

        source
      end

      def select_endpoints(doc, start, finish)
        # targeting range of elements as end_selector is present
        #
        finish = "#{start} ~ #{finish}"
        starting    = doc.css(start).first

        ending = if starting && starting.parent
          starting.parent.css(finish).first
        else
          doc.css(finish).first
        end

        return starting, ending
      end

      # finds all elements upto closing sibling in nokgiri document
      #
      def select_range(first, last)
        first == last ? [first] : [first, *select_range(first.next, last)]
      end

      private

        def normalize_attribute_name(name)
          name = name.to_s.gsub /"|'/, ''

          if /\Adata-erb-/ =~ name
            name.gsub! /\Adata-erb-/, ''
          end

          name
        end

    end
  end
end
