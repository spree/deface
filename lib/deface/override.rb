module Deface
  class Override
    include TemplateHelper
    include OriginalValidator
    extend Applicator::ClassMethods
    extend Search::ClassMethods

    cattr_accessor :actions, :sources, :_early
    attr_accessor :args, :parsed_document

    @@_early = []
    @@actions = [:remove, :replace, :replace_contents, :surround, :surround_contents, :insert_after, :insert_before, :insert_top, :insert_bottom, :set_attributes, :add_to_attributes, :remove_from_attributes]
    @@sources = [:text, :erb, :haml, :partial, :template, :cut, :copy]

    # Initializes new override, you must supply only one Target, Action & Source
    # parameter for each override (and any number of Optional parameters).
    #
    # See READme for more!
    def initialize(args, &content)
      if Rails.application.try(:config).try(:deface).try(:enabled)
        unless Rails.application.config.deface.try(:overrides)
          @@_early << args
          warn "[WARNING] You no longer need to manually require overrides, remove require for '#{args[:name]}'."
          return
        end
      else
        warn "[WARNING] You no longer need to manually require overrides, remove require for '#{args[:name]}'."
        return
      end

      raise(ArgumentError, ":name must be defined") unless args.key? :name
      raise(ArgumentError, ":virtual_path must be defined") if args[:virtual_path].blank?

      args[:text] = content.call if block_given?

      virtual_key = args[:virtual_path].to_sym
      name_key = args[:name].to_s.parameterize

      self.class.all[virtual_key] ||= {}

      if self.class.all[virtual_key].has_key? name_key
        #updating exisiting override

        @args = self.class.all[virtual_key][name_key].args

        #check if the action is being redefined, and reject old action
        if (@@actions & args.keys).present?
          @args.reject!{|key, value| (@@actions & @args.keys).include? key }
        end

        #check if the source is being redefined, and reject old action
        if (@@sources & args.keys).present?
          @args.reject!{|key, value| (@@sources & @args.keys).include? key }
        end

        @args.merge!(args)
      else
        #initializing new override
        @args = args

        raise(ArgumentError, ":action is invalid") if self.action.nil?
      end

      #set loaded time (if not already present) for hash invalidation
      @args[:updated_at] ||= Time.zone.now.to_f

      self.class.all[virtual_key][name_key] = self

      expire_compiled_template

      self
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

          if self.class.all[key].key? ref_name.to_s
            return self.class.all[key][ref_name.to_s].sequence - 1
          else
            return 100
          end
        elsif @args[:sequence].key? :after
          ref_name = @args[:sequence][:after]

          if self.class.all[key].key? ref_name.to_s
            return self.class.all[key][ref_name.to_s].sequence + 1
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
      erb = case source_argument
      when :partial
        load_template_source(@args[:partial], true)
      when :template
        load_template_source(@args[:template], false)
      when :text
        @args[:text]
      when :erb
        @args[:erb]
      when :cut
        cut = @args[:cut]

        if cut.is_a? Hash
          starting, ending = self.class.select_endpoints(self.parsed_document, cut[:start], cut[:end])

          range = self.class.select_range(starting, ending)
          range.map &:remove

          Deface::Parser.undo_erb_markup! range.map(&:to_s).join

        else
          Deface::Parser.undo_erb_markup! self.parsed_document.css(cut).first.remove.to_s.clone
        end

      when :copy
        copy = @args[:copy]

        if copy.is_a? Hash
          starting, ending = self.class.select_endpoints(self.parsed_document, copy[:start], copy[:end])

          range = self.class.select_range(starting, ending)

          Deface::Parser.undo_erb_markup! range.map(&:to_s).join
        else
         Deface::Parser.undo_erb_markup! parsed_document.css(copy).first.to_s.clone
        end

      when :haml
        if Rails.application.config.deface.haml_support
          haml_engine = Deface::HamlConverter.new(@args[:haml])
          haml_engine.render
        else
          raise Deface::NotSupportedError, "`#{self.name}` supplies :haml source, but haml_support is not detected."
        end
      end

      erb
    end

    # Returns a :symbol for the source argument present
    #
    def source_argument
      @@sources.detect { |source| @args.key? source }
    end

    def source_element
      Deface::Parser.convert(source.clone)
    end

    def safe_source_element
      return unless source_argument
      source_element
    end

    def disabled?
      @args.key?(:disabled) ? @args[:disabled] : false
    end

    def end_selector
      return nil if @args[:closing_selector].blank?
      @args[:closing_selector]
    end

    def attributes
      @args[:attributes] || []
    end

    # Alters digest of override to force view method
    # recompilation (when source template/partial changes)
    #
    def touch
      @args[:updated_at] = Time.zone.now.to_f
    end

    # Creates MD5 hash of args sorted keys and values
    # used to determine if an override has changed
    #
    def digest
      Digest::MD5.new.update(@args.keys.map(&:to_s).sort.concat(@args.values.map(&:to_s).sort).join).hexdigest
    end

    # Creates MD5 of all overrides that apply to a particular
    # virtual_path, used in CompiledTemplates method name
    # so we can support re-compiling of compiled method
    # when overrides change. Only of use in production mode.
    #
    def self.digest(details)
      overrides = self.find(details)

      Digest::MD5.new.update(overrides.inject('') { |digest, override| digest << override.digest }).hexdigest
    end

    def self.all
      Rails.application.config.deface.overrides.all
    end

    def execute_action target_element
      validate_original target_element
      create_action_command.execute target_element
    end

    def execute_action_on_range target_range
      create_action_command.execute_on_range target_range
    end

    def create_action_command
      commands = Rails.application.config.deface.actions
      command = commands.find { |command| command.desired_action? action }
      raise(DefaceError, "Action #{action} not found") unless command
      command.new(source_element: safe_source_element, attributes: attributes)
    end

    private

      # check if method is compiled for the current virtual path
      #
      def expire_compiled_template
        if compiled_method_name = ActionView::CompiledTemplates.instance_methods.detect { |name| name =~ /#{args[:virtual_path].gsub(/[^a-z_]/, '_')}/ }
          #if the compiled method does not contain the current deface digest
          #then remove the old method - this will allow the template to be
          #recompiled the next time it is rendered (showing the latest changes)

          unless compiled_method_name =~ /\A_#{self.class.digest(:virtual_path => @args[:virtual_path])}_/
            ActionView::CompiledTemplates.send :remove_method, compiled_method_name
          end
        end

      end

  end

end
