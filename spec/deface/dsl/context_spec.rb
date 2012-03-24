require 'spec_helper'

require 'deface/dsl/context'

describe Deface::DSL::Context do
  include_context "mock Rails"

  context '#create_override' do
    subject { context = Deface::DSL::Context.new('sample_name') }

    def override_should_be_created_with(expected_hash)
      Deface::Override.should_receive(:new).with(hash_including(
        :name => 'sample_name'
      ))

      subject.create_override
    end

    it 'should use name passed in through initializer' do
      override_should_be_created_with(:name => 'sample_name')
    end

    it 'should use value set with #virtual_path' do
      subject.virtual_path('test/path')

      override_should_be_created_with(:virtual_path => 'test/path')
    end

    context 'actions' do
      Deface::Override.actions.each do |action|
        it "should use value set with ##{action}" do
          subject.send(action, "#{action}/selector")

          override_should_be_created_with(action => "#{action}/selector")
        end
      end

      it 'should generate a warning if two action values are specified' do
        subject.insert_top('selector')
        
        logger = mock('logger')
        Rails.should_receive(:logger).and_return(logger)
        logger.should_receive(:error).with("\e[1;32mDeface: [WARNING]\e[0m Multiple action methods have been called. The last one will be used.")

        subject.insert_bottom('selector')
      end

      it 'should use the last action that is specified' do
        Rails.stub_chain(:logger, :error)

        subject.insert_top('insert_top/selector')
        subject.insert_bottom('insert_bottom/selector')

        override_should_be_created_with(:insert_bottom => 'insert_bottom/selector')        
      end
    end

    context 'sources' do
      Deface::Override.sources.each do |source|
        it "should use value set with ##{source}" do
          subject.send(source, "#{source} value")

          override_should_be_created_with(source => "#{source} value")
        end
      end

      it 'should generate a warning if two sources are specified' do
        subject.partial('partial name')

        logger = mock('logger')
        Rails.should_receive(:logger).and_return(logger)
        logger.should_receive(:error).with("\e[1;32mDeface: [WARNING]\e[0m Multiple source methods have been called. The last one will be used.")

        subject.template('template/path')
      end

      it 'should use the last source that is specified' do
        Rails.stub_chain(:logger, :error)

        subject.partial('partial name')
        subject.template('template/path')

        override_should_be_created_with(:template => 'template/path')
      end
    end

    # * <tt>:original</tt> - String containing original markup that is being overridden.
    #   If supplied Deface will log when the original markup changes, which helps highlight overrides that need 
    #   attention when upgrading versions of the source application. Only really warranted for :replace overrides.
    #   NB: All whitespace is stripped before comparsion.
    it 'should use value set with #original' do
      subject.original('<div>original markup</div>')

      override_should_be_created_with(:original => '<div>original markup</div>')
    end

    # * <tt>:closing_selector</tt> - A second css selector targeting an end element, allowing you to select a range 
    #   of elements to apply an action against. The :closing_selector only supports the :replace, :remove and 
    #   :replace_contents actions, and the end element must be a sibling of the first/starting element. Note the CSS
    #   general sibling selector (~) is used to match the first element after the opening selector.
    it 'should use value set wih #closing_selector' do
      subject.closing_selector('closing/selector')

      override_should_be_created_with(:closing_selector => 'closing/selector')
    end
    
    # * <tt>:sequence</tt> - Used to order the application of an override for a specific virtual path, helpful when
    #   an override depends on another override being applied first.
    #   Supports:
    #   :sequence => n - where n is a positive or negative integer (lower numbers get applied first, default 100).
    #   :sequence => {:before => "override_name"} - where "override_name" is the name of an override defined for the 
    #                                               same virutal_path, the current override will be appplied before 
    #                                               the named override passed.
    #   :sequence => {:after => "override_name") - the current override will be applied after the named override passed.
    it 'should use hash value set with #sequence' do
      subject.sequence(:before => 'something')

      override_should_be_created_with(:sequence => {:before => 'something'})
    end

    it 'should use integer value set with #sequence' do
      subject.sequence(12)

      override_should_be_created_with(:sequence => 12)
    end

    ## todo: combine #set_attributes and attributes for clarity

    # * <tt>:attributes</tt> - A hash containing all the attributes to be set on the matched elements, eg: :attributes => {:class => "green", :title => "some string"}
    it 'should use value set with attributes' do
      subject.attributes(:class => "green", :title => "some string")

      override_should_be_created_with(:attributes => {:class => "green", :title => "some string"})
    end

    # * <tt>:disabled</tt> - When set to true the override will not be applied.
    it 'should pass { :disabled => true } when #disabled is called' do
      subject.disabled

      override_should_be_created_with(:disabled => true)
    end

    it 'should pass { :disabled => false} #enabled is called' do
      subject.enabled

      override_should_be_created_with(:disabled => false)
    end
  end
end
