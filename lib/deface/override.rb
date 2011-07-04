module Deface
  class Override
    include Deface::TemplateHelper

    cattr_accessor :all, :actions
    attr_accessor :args

    @@all ||= {}
    @@actions = [:remove, :replace, :insert_after, :insert_before, :insert_top, :insert_bottom]

    # Initializes new override, you must supply only one Target, Action & Source
    # parameter for each override (and any number of Optional parameters).
    #
    # ==== Target
    #
    # * <tt>:virtual_path</tt> - The path of the template / partial where
    #   the override should take effect eg: "shared/_person", "admin/posts/new"
    #   this will apply to all controller actions that use the specified template
    #
    # ==== Action
    #
    # * <tt>:remove</tt> - Removes all elements that match the supplied selector
    # * <tt>:replace</tt> - Replaces all elements that match the supplied selector
    # * <tt>:insert_after</tt> - Inserts after all elements that match the supplied selector
    # * <tt>:insert_before</tt> - Inserts before all elements that match the supplied selector
    # * <tt>:insert_top</tt> - Inserts inside all elements that match the supplied selector, before all existing child
    # * <tt>:insert_bottom</tt> - Inserts inside all elements that match the supplied selector, after all existing child
    #
    # ==== Source
    #
    # * <tt>:text</tt> - String containing markup
    # * <tt>:partial</tt> - Relative path to partial
    # * <tt>:template</tt> - Relative path to template
    #
    # ==== Optional
    #
    # * <tt>:name</tt> - Unique name for override so it can be identified and modified later.
    #   This needs to be unique within the same :virtual_path
    # * <tt>:disabled</tt> - When set to true the override will not be applied.
    # * <tt>:original</tt> - String containing original markup that is being overridden.
    #   If supplied Deface will log when the original markup changes, which helps highlight overrides that need 
    #   attention when upgrading versions of the source application. Only really warranted for :replace overrides.
    #   NB: All whitespace is stripped before comparsion.
    # * <tt>:sequence</tt> - Used to order the application of an override for a specific virtual path, helpful when
    #   an override depends on another override being applied first.
    #   Supports:
    #   :sequence => n - where n is a positive or negative integer (lower numbers get applied first, default 100).
    #   :sequence => {:before => "override_name"} - where "override_name" is the name of an override defined for the 
    #                                               same virutal_path, the current override will be appplied before 
    #                                               the named override passed.
    #   :sequence => {:after => "override_name") - the current override will be applied after the named override passed.
    #
    def initialize(args)
      @args = args

      raise(ArgumentError, "Invalid action") if self.action.nil?
      raise(ArgumentError, ":virtual_path must be defined") if args[:virtual_path].blank?

      key = args[:virtual_path].to_sym

      @@all[key] ||= {}
      @@all[key][args[:name].to_s.parameterize] = self
    end

    def selector
      @args[self.action]
    end

    def name
      @args[:name]
    end

    def sequence
      return 100 unless @args.key?(:sequence)
      if @args[:sequence].is_a? Hash
        key = @args[:virtual_path].to_sym

        if @args[:sequence].key? :before
          ref_name = @args[:sequence][:before]

          if @@all[key].key? ref_name.to_s
            return @@all[key][ref_name.to_s].sequence - 1
          else
            return 100
          end
        elsif @args[:sequence].key? :after
          ref_name = @args[:sequence][:after]

          if @@all[key].key? ref_name.to_s
            return @@all[key][ref_name.to_s].sequence + 1
          else
            return 100
          end
        else
          #should never happen.. tut tut!
          return 100
        end

      else
        return @args[:sequence].to_i 
      end
    rescue SystemStackError
      if defined?(Rails) 
        Rails.logger.error "\e[1;32mDeface: [WARNING]\e[0m Circular sequence dependency includes override named: '#{self.name}' on '#{@args[:virtual_path]}'."
      end

      return 100
    end

    def action
      (@@actions & @args.keys).first
    end

    def source
      erb = if @args.key? :partial
        load_template_source(@args[:partial], true)
      elsif @args.key? :template
        load_template_source(@args[:template], false)
      elsif @args.key? :text
        @args[:text]
      end
    end

    def source_element
      Deface::Parser.convert(source.clone)
    end

    def original_source
      return nil unless @args[:original].present?

      Deface::Parser.convert(@args[:original].clone)
    end

    # logs if original source has changed
    def validate_original(match)
      return true if self.original_source.nil?

      valid = self.original_source.to_s.gsub(/\s/, '') == match.to_s.gsub(/\s/, '')

      if !valid && defined?(Rails) == "constant"
        Rails.logger.error "\e[1;32mDeface: [WARNING]\e[0m The original source for '#{self.name}' has changed, this override should be reviewed to ensure it's still valid."
      end

      valid
    end

    def disabled?
      @args.key?(:disabled) ? @args[:disabled] : false
    end

    def end_selector
      @args[:closing_selector]
    end

    # applies all applicable overrides to given source
    #
    def self.apply(source, details)
      overrides = find(details)
      @enable_logging ||= defined?(Rails) == "constant"

      if @enable_logging && overrides.size > 0
        Rails.logger.info "\e[1;32mDeface:\e[0m #{overrides.size} overrides found for '#{details[:virtual_path]}'"
      end

      unless overrides.empty?
        doc = Deface::Parser.convert(source)

        overrides.each do |override|
          if override.disabled?
            Rails.logger.info("\e[1;32mDeface:\e[0m '#{override.name}' is disabled") if @enable_logging
            next
          end

          if override.end_selector.blank?
            # single css selector

            matches = doc.css(override.selector)

            if @enable_logging
              Rails.logger.send(matches.size == 0 ? :error : :info, "\e[1;32mDeface:\e[0m '#{override.name}' matched #{matches.size} times with '#{override.selector}'")
            end

            matches.each do |match|
              override.validate_original(match)

              case override.action
                when :remove
                  match.replace ""
                when :replace
                  match.replace override.source_element
                when :insert_before
                  match.before override.source_element
                when :insert_after
                  match.after override.source_element
                when :insert_top
                  match.children.before(override.source_element)
                when :insert_bottom
                  match.children.after(override.source_element)
              end

            end
          else
            # targeting range of elements as end_selector is present
            starting    = doc.css(override.selector).first
            if starting && starting.parent
              ending = starting.parent.css(override.end_selector).first
            else
              ending = doc.css(override.end_selector).first
            end

            if starting && ending
              elements = select_range(starting, ending)

              if override.action == :replace
                starting.before(override.source_element)
              end

              #now remove all matched elements
              elements.map &:remove
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

    # finds all applicable overrides for supplied template
    #
    def self.find(details)
      return [] if @@all.empty? || details.empty?

      virtual_path = details[:virtual_path]
      return [] if virtual_path.nil?

      result = []
      result << @@all[virtual_path.to_sym].try(:values)

      result.flatten.compact.sort_by &:sequence
    end

    private
      # finds all elements upto closing sibling in nokgiri document
      #
      def self.select_range(first, last)
        first == last ? [first] : [first, *select_range(first.next, last)]
      end

  end

end
