module Deface
  class Override
    include TemplateHelper
    include OriginalValidator
    extend Applicator::ClassMethods
    extend Search::ClassMethods

    cattr_accessor :actions, :_early
    attr_accessor :args

    @@_early = []
    @@actions = [:remove, :replace, :replace_contents, :surround, :surround_contents, :insert_after, :insert_before, :insert_top, :insert_bottom, :set_attributes, :add_to_attributes, :remove_from_attributes, :move_top, :move_bottom]
    @@sources = [:text, :erb, :haml, :partial, :template]

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
    # * <tt>:replace_contents</tt> - Replaces the contents of all elements that match the supplied selector
    # * <tt>:surround</tt> - Surrounds all elements that match the supplied selector, expects replacement markup to contain <%= render_original %> placeholder
    # * <tt>:surround_contents</tt> - Surrounds the contents of all elements that match the supplied selector, expects replacement markup to contain <%= render_original %> placeholder
    # * <tt>:insert_after</tt> - Inserts after all elements that match the supplied selector
    # * <tt>:insert_before</tt> - Inserts before all elements that match the supplied selector
    # * <tt>:insert_top</tt> - Inserts inside all elements that match the supplied selector, before all existing child
    # * <tt>:insert_bottom</tt> - Inserts inside all elements that match the supplied selector, after all existing child
    # * <tt>:set_attributes</tt> - Sets attributes on all elements that match the supplied selector, replacing existing attribute value if present or adding if not. Expects :attributes option to be passed.
    # * <tt>:add_to_attributes</tt> - Appends value to attributes on all elements that match the supplied selector, adds attribute if not present. Expects :attributes option to be passed.
    # * <tt>:remove_from_attributes</tt> - Removes value from attributes on all elements that match the supplied selector. Expects :attributes option to be passed.
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
    # * <tt>:closing_selector</tt> - A second css selector targeting an end element, allowing you to select a range
    #   of elements to apply an action against. The :closing_selector only supports the :replace, :remove and
    #   :replace_contents actions, and the end element must be a sibling of the first/starting element. Note the CSS
    #   general sibling selector (~) is used to match the first element after the opening selector.
    # * <tt>:sequence</tt> - Used to order the application of an override for a specific virtual path, helpful when
    #   an override depends on another override being applied first.
    #   Supports:
    #   :sequence => n - where n is a positive or negative integer (lower numbers get applied first, default 100).
    #   :sequence => {:before => "override_name"} - where "override_name" is the name of an override defined for the
    #                                               same virutal_path, the current override will be appplied before
    #                                               the named override passed.
    #   :sequence => {:after => "override_name") - the current override will be applied after the named override passed.
    # * <tt>:attributes</tt> - A hash containing all the attributes to be set on the matched elements, eg: :attributes => {:class => "green", :title => "some string"}
    #
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

    def destination
      @args[:to]
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
      erb = if @args.key? :partial
        load_template_source(@args[:partial], true)
      elsif @args.key? :template
        load_template_source(@args[:template], false)
      elsif @args.key? :text
        @args[:text]
      elsif @args.key? :erb
        @args[:erb]
      elsif @args.key?(:haml) && Rails.application.config.deface.haml_support
        haml_engine = Deface::HamlConverter.new(@args[:haml])
        haml_engine.render
      end

      erb
    end

    def source_element
      Deface::Parser.convert(source.clone)
    end

    def disabled?
      @args.key?(:disabled) ? @args[:disabled] : false
    end

    def end_selector
      return nil if @args[:closing_selector].blank?
      "#{self.selector} ~ #{@args[:closing_selector]}"
    end

    def attributes
      @args[:attributes] || []
    end

    def digest
      Digest::MD5.new.update(@args.to_s).hexdigest
    end

    def self.all
      Rails.application.config.deface.overrides.all
    end

    def self.digest(details)
      overrides = self.find(details)

      Digest::MD5.new.update(overrides.inject('') { |digest, override| digest << override.digest }).hexdigest
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
