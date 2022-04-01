module Deface
  class Override
    include OriginalValidator
    include Applicator
    extend Applicator::ClassMethods
    extend Search::ClassMethods

    cattr_accessor :_early, :current_railtie
    attr_accessor :args, :parsed_document, :failure

    @@_early = []

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

      # If no name was specified, use the filename and line number of the caller
      # Including the line number ensure unique names if multiple overrides
      # are defined in the same file
      unless args.key? :name
        parts = caller[0].split(':')
        file_name = File.basename(parts[0], '.rb')
        line_number = parts[1]
        args[:name] = "#{file_name}_#{line_number}"
      end

      raise(ArgumentError, ":name must be defined") unless args.key? :name
      raise(ArgumentError, ":virtual_path must be defined") if args[:virtual_path].blank?

      args[:text] = content.call if block_given?
      args[:name] = "#{current_railtie.underscore}_#{args[:name]}" if Rails.application.try(:config).try(:deface).try(:namespaced) || args.delete(:namespaced)

      virtual_key = args[:virtual_path].to_sym
      name_key = args[:name].to_s.parameterize

      self.class.all[virtual_key] ||= {}

      if self.class.all[virtual_key].has_key? name_key
        #updating exisiting override

        @args = self.class.all[virtual_key][name_key].args

        #check if the action is being redefined, and reject old action
        if (self.class.actions & args.keys).present?
          @args.reject!{|key, value| (self.class.actions & @args.keys).include? key }
        end

        #check if the source is being redefined, and reject old action
        if (Deface::DEFAULT_SOURCES.map(&:to_sym) & args.keys).present?
          @args.reject!{|key, value| (Deface::DEFAULT_SOURCES.map(&:to_sym) & @args.keys).include? key }
        end

        @args.merge!(args)
      else
        #initializing new override
        @args = args

        raise(ArgumentError, ":action is invalid") if self.action.nil?
      end

      # Set loaded time (if not already present) for hash invalidation
      @args[:updated_at] ||= Time.current.to_f
      @args[:railtie_class] = self.class.current_railtie

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

    def railtie_class
      @args[:railtie_class]
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
      (self.class.actions & @args.keys).first
    end

    # Returns the markup to be inserted / used
    #
    def source
      sources = Rails.application.config.deface.sources
      source = sources.find { |source| source.to_sym == source_argument }
      raise(DefaceError, "Source #{source} not found.") unless source

      source.execute(self) || ''
    end

    # Returns a :symbol for the source argument present
    #
    def source_argument
      Deface::DEFAULT_SOURCES.detect { |source| @args.key? source.to_sym }.try :to_sym
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

    # returns attributes hash for attribute related actions
    #
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
      to_hash = @args.keys.map(&:to_s).sort.concat(@args.values.map(&:to_s).sort).join
      Deface::Digest.hexdigest(to_hash)
    end

    # Creates MD5 of all overrides that apply to a particular
    # virtual_path, used in CompiledTemplates method name
    # so we can support re-compiling of compiled method
    # when overrides change. Only of use in production mode.
    #
    def self.digest(details)
      overrides = self.find(details)
      to_hash = overrides.inject('') { |digest, override| digest << override.digest }
      Deface::Digest.hexdigest(to_hash)
    end

    def self.all
      Rails.application.config.deface.overrides.all
    end

    def self.actions
      Rails.application.config.deface.actions.map &:to_sym
    end


    private

    # Check if method is compiled for the current virtual path.
    #
    # If the compiled method does not contain the current deface digest
    # then remove the old method - this will allow the template to be
    # recompiled the next time it is rendered (showing the latest changes).
    def expire_compiled_template
      virtual_path = args[:virtual_path]

      method_name = Deface.template_class.instance_methods.detect do |name|
        name =~ /#{virtual_path.gsub(/[^a-z_]/, '_')}/
      end

      if method_name && method_name !~ /\A_#{self.class.digest(virtual_path: virtual_path)}_/
        Deface.template_class.send :remove_method, method_name
      end
    end
  end

end
