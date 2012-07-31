require 'spec_helper'

module ActionView
  describe Template do
    include_context "mock Rails.application"

    describe "with no overrides defined" do
      before(:each) do
        @updated_at = Time.now - 600
        @template = ActionView::Template.new("<p>test</p>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html, :updated_at => @updated_at})
        #stub for Rails < 3.1
        unless defined?(@template.updated_at)
          @template.stub(:updated_at).and_return(@updated_at)
        end
      end

      it "should initialize new template object" do
        @template.is_a?(ActionView::Template).should == true
      end

      it "should return unmodified source" do
        @template.source.should == "<p>test</p>"
      end

      it "should not change updated_at" do
        @template.updated_at.should == @updated_at
      end

    end

    describe "with a single remove override defined" do
      before(:each) do
        @updated_at = Time.now - 300
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove => "p", :text => "<h1>Argh!</h1>")
        @template = ActionView::Template.new("<p>test</p><%= raw(text) %>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html, :updated_at => @updated_at})
        #stub for Rails < 3.1
        unless defined?(@template.updated_at)
          @template.stub(:updated_at).and_return(@updated_at + 500)
        end
      end

      it "should return modified source" do
        @template.source.should == "<%= raw(text) %>"
      end

      it "should change updated_at" do
        @template.updated_at.should > @updated_at
      end
    end

    describe "method_name" do
      let(:template) { ActionView::Template.new("<p>test</p>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html, :updated_at => (Time.now - 100)}) }

      it "should return hash of overrides plus original method_name " do
        deface_hash = Deface::Override.digest(:virtual_path => 'posts/index')

        template.send(:method_name).should == "_#{Digest::MD5.new.update("#{deface_hash}_#{template.send(:method_name_without_deface)}").hexdigest}"
      end

      it "should alias original method_name method" do
        template.send(:method_name_without_deface).should match /\A__some_path_to_file_erb_+[0-9]+_+[0-9]+\z/
      end
    end

    describe "non erb or haml template" do
      before(:each) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove => "p")
        @template = ActionView::Template.new("xml.post => :blah", "/some/path/to/file.erb", ActionView::Template::Handlers::Builder, {:virtual_path=>"posts/index", :format=>:xml, :updated_at => (Time.now - 100)})
      end

      it "should return unmodified source" do
        #if processed, source would include "=&gt;"
        @template.source.should == "xml.post => :blah"
      end
    end

    describe "#should_be_defaced?(handler) method" do
      #not so BDD, but it keeps us from making mistakes in the future
      #for instance, we test ActionView::Template here with a handler == ....::Handlers::ERB,
      #while in rails it seems it's an instance of ...::Handlers::ERB
      it "should be truthy only for haml/erb handlers and their instances" do
        expectations = { Haml::Plugin => true,
                         ActionView::Template::Handlers::ERB => true,
                         ActionView::Template::Handlers::ERB.new => true,
                         ActionView::Template::Handlers::Builder => false }
        expectations.each do |handler, expected|
          @template = ActionView::Template.new("xml.post => :blah", "/some/path/to/file.erb", handler, {:virtual_path=>"posts/index", :format=>:xml, :updated_at => (Time.now - 100)})
          @template.is_a?(ActionView::Template).should == true
          @template.send(:should_be_defaced?, handler).should eq(expected), "unexpected result for handler "+handler.to_s
        end
      end
    end
  end
end
