require 'spec_helper'

module ActionView
  describe Template do
    include_context "mock Rails.application"

    describe "with no overrides defined" do
      before(:each) do
        @updated_at = Time.now - 600

        @template = ActionView::Template.new(
          "<p>test</p>",
          "/some/path/to/file.erb",
          ActionView::Template::Handlers::ERB,
          virtual_path: "posts/index",
          format: :html,
          updated_at: @updated_at
        )
      end

      it "should initialize new template object" do
        expect(@template.is_a?(ActionView::Template)).to eq(true)
      end

      it "should return unmodified source" do
        expect(@template.source).to eq("<p>test</p>")
      end

      it "should not change updated_at" do
        expect(@template.updated_at).to eq(@updated_at)
      end

    end

    describe "with a single remove override defined" do
      before(:each) do
        @updated_at = Time.now - 300
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove => "p", :text => "<h1>Argh!</h1>")
        @template = ActionView::Template.new("<p>test</p><%= raw(text) %>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html, :updated_at => @updated_at})
        #stub for Rails < 3.1
        unless defined?(@template.updated_at)
          allow(@template).to receive(:updated_at).and_return(@updated_at + 500)
        end
      end

      it "should return modified source" do
        expect(@template.source).to eq("<%= raw(text) %>")
      end

      if Deface.before_rails_6?
        it "should change updated_at" do
          expect(@template.updated_at).to be > @updated_at
        end
      else
        it "should not change updated_at" do
          expect(@template.updated_at).to eq(@updated_at)
        end
      end
    end

    describe "method_name" do
      let(:template) { ActionView::Template.new("<p>test</p>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html, :updated_at => (Time.now - 100)}) }

      it "should return hash of overrides plus original method_name " do
        deface_hash = Deface::Override.digest(:virtual_path => 'posts/index')

        expect(template.send(:method_name)).to eq("_#{Digest::MD5.new.update("#{deface_hash}_#{template.send(:method_name_without_deface)}").hexdigest}")
      end

      it "should alias original method_name method" do
        expect(template.send(:method_name_without_deface)).to match /\A__some_path_to_file_erb_+[0-9]+_+[0-9]+\z/
      end
    end

    describe "non erb or haml template" do
      before(:each) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove => "p")
        @template = ActionView::Template.new("xml.post => :blah", "/some/path/to/file.erb", ActionView::Template::Handlers::Builder, {:virtual_path=>"posts/index", :format=>:xml, :updated_at => (Time.now - 100)})
      end

      it "should return unmodified source" do
        #if processed, source would include "=&gt;"
        expect(@template.source).to eq("xml.post => :blah")
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
          expect(@template.is_a?(ActionView::Template)).to eq(true)
          syntax = @template.send(:determine_syntax, handler)
          expect(@template.send(:should_be_defaced?, syntax)).to eq(expected), "unexpected result for handler "+handler.to_s
        end
      end
    end
  end
end
