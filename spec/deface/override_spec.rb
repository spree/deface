require 'spec_helper'

module Deface
  describe Override do
    include_context "mock Rails.application"

    before(:each) do
      @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>")
    end

    it "should return correct action" do
      Deface::Override.actions.each do |action|
        Rails.application.config.deface.overrides.all.clear
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", action => "h1", :text => "<h1>Argh!</h1>")
        @override.action.should == action
      end
    end

    it "should have a sources method" do
      Deface::Override.sources.should include(:text)
    end

    it "should return correct selector" do
      @override.selector.should == "h1"
    end

    describe "#original_source" do
      it "should return nil with not specified" do
        @override.original_source.should be_nil
      end

      it "should return parsed nokogiri document when present" do
        @original = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>", :original => "<p><%= something %></p>")
        @original.original_source.should be_an_instance_of Nokogiri::HTML::DocumentFragment
        @original.original_source.to_s.should == "<p><code erb-loud> something </code></p>"
      end
    end

    describe "#validate_original when :original is not present" do
      before(:each) do
        @original = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>")
      end

      it "should warn but not validate" do
        Rails.logger.should_receive(:info).once
        @override.validate_original("<p>this gets ignored</p>").should be_nil
      end

    end

    describe "#validate_original when :original is present" do
      before(:each) do
        @original = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>", :original => "<p><%= something %></p>")
      end

      it "should return true when input contains similar (ignoring whitespace)" do
        @original.validate_original("<p><code erb-loud> something </code></p>").should be_true
        @original.validate_original("<p><code erb-loud>something\n</code>  </p>").should be_true
      end

      it "should return false when and input contains different string" do
        @original.validate_original("wrong").should be_false
      end
    end

    describe "#find" do
      it "should find by virtual_path" do
        Deface::Override.find({:virtual_path => "posts/index"}).size.should == 1
        Deface::Override.find({:virtual_path => "/posts/index"}).size.should == 1
        Deface::Override.find({:virtual_path => "/posts/index.html"}).size.should == 1
        Deface::Override.find({:virtual_path => "posts/index.html"}).size.should == 1
      end

      it "should return empty array when no details hash passed" do
        Deface::Override.find({}).should == []
      end
    end

    describe "#new" do

      it "should increase all#size by 1" do
        expect {
          Deface::Override.new(:virtual_path => "posts/new", :name => "Posts#new", :replace => "h1", :text => "<h1>argh!</h1>")
        }.to change{Deface::Override.all.size}.by(1)
      end
    end

    describe "with :text" do

      before(:each) do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1 id=\"<%= dom_id @pirate %>\">Argh!</h1>")
      end

      it "should return un-convert text as source" do
        @override.source.should == "<h1 id=\"<%= dom_id @pirate %>\">Argh!</h1>"
      end
    end

    describe "with :erb" do

      before(:each) do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1 id=\"<%= dom_id @pirate %>\">Argh!</h1>")
      end

      it "should return un-convert text as source" do
        @override.source.should == "<h1 id=\"<%= dom_id @pirate %>\">Argh!</h1>"
      end
    end

    describe "with :haml" do

      before(:each) do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1",
                                         :haml => %q{%strong{:class => "code", :id => "message"}= 'Hello, World!'})
      end

      it "should return erb converted from haml as source" do
        @override.source.should == "<strong class='code' id='message'><%= 'Hello, World!' %>\n</strong>\n"
      end
    end


    describe "with :partial containing erb" do

      before(:each) do
        #stub view paths to be local spec/assets directory
        ActionController::Base.stub(:view_paths).and_return([File.join(File.dirname(__FILE__), '..', "assets")])

        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :partial => "shared/post")
      end

      it "should return un-convert partial contents as source" do
        @override.source.should == "<p>I'm from shared/post partial</p>\n<%= \"And I've got ERB\" %>\n"
      end

    end

    describe "with :template" do

      before(:each) do
        #stub view paths to be local spec/assets directory
        ActionController::Base.stub(:view_paths).and_return([File.join(File.dirname(__FILE__), '..', "assets")])

        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :template => "shared/person")
      end

      it "should return un-convert template contents as source" do
        @override.source.should == "<p>I'm from shared/person template</p>\n<%= \"I've got ERB too\" %>\n"
      end

    end

    describe "with block" do
      before(:each) do
        #stub view paths to be local spec/assets directory
        ActionController::Base.stub(:view_paths).and_return([File.join(File.dirname(__FILE__), '..', "assets")])

        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1") do
          "This is replacement text for the h1"
        end
      end

      it "should set source to block content" do
        @override.source.should == "This is replacement text for the h1"
      end
    end

    describe "#source_element" do
      before(:each) do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<%= method :opt => 'x' & 'y' %>")
      end

      it "should return escaped source" do
        @override.source_element.should be_an_instance_of Nokogiri::HTML::DocumentFragment
        @override.source_element.to_s.should == "<code erb-loud> method :opt =&gt; 'x' &amp; 'y' </code>"
        #do it twice to ensure it doesn't change as it's destructive
        @override.source_element.to_s.should == "<code erb-loud> method :opt =&gt; 'x' &amp; 'y' </code>"
      end
    end

    describe "when redefining an override without changing action or source type" do
      before(:each) do
        Rails.application.config.deface.overrides.all.clear
        @override    = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :text => "<h1>Argh!</h1>", :replace => "h1")
        expect {
          @replacement = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :text => "<h1>Arrrr!</h1>")
        }.to change{Rails.application.config.deface.overrides.all.size}.by(0)
      end

      it "should return new source" do
        @replacement.source.should_not == "<h1>Argh!</h1>"
        @replacement.source.should == "<h1>Arrrr!</h1>"
      end

    end

    describe "when redefining an override when changing action" do
      before(:each) do
        Rails.application.config.deface.overrides.all.clear
        @override    = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1")
        expect {
          @replacement = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_after => "h1")
        }.to change{Rails.application.config.deface.overrides.all.size}.by(0)
      end

      it "should return new action" do
        @replacement.action.should == :insert_after
      end

      it "should remove old action" do
        @replacement.args.has_key?(:replace).should be_false
      end

    end

    describe "when redefining an override when changing source type" do
      before(:each) do
        #stub view paths to be local spec/assets directory
        ActionController::Base.stub(:view_paths).and_return([File.join(File.dirname(__FILE__), '..', "assets")])

        Rails.application.config.deface.overrides.all.clear
        @override    = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :partial => "shared/post", :replace => "h1")
        expect {
          @replacement = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :text => "<p>I do be a pirate!</p>")
        }.to change{Rails.application.config.deface.overrides.all.size}.by(0)
      end

      it "should return new source" do
        @override.source.should == "<p>I do be a pirate!</p>"
      end

    end


    describe "#sequence" do
      it "should calculate correct after sequences" do
        @third = Deface::Override.new(:virtual_path => "posts/index", :name => "third", :insert_after => "li:contains('second')", :text => "<li>third</li>", :sequence => {:after => "second"})
        @second = Deface::Override.new(:virtual_path => "posts/index", :name => "second", :insert_after => "li", :text => "<li>second</li>", :sequence => {:after => "first"})
        @first = Deface::Override.new(:virtual_path => "posts/index", :name => "first", :replace => "li", :text => "<li>first</li>")

        @third.sequence.should == 102
        @second.sequence.should == 101
        @first.sequence.should == 100
      end

      it "should calculate correct before sequences" do
        @second = Deface::Override.new(:virtual_path => "posts/index", :name => "second", :insert_after => "li", :text => "<li>second</li>", :sequence => 99)
        @first = Deface::Override.new(:virtual_path => "posts/index", :name => "first", :replace => "li", :text => "<li>first</li>", :sequence => {:before => "second"})

        @second.sequence.should == 99
        @first.sequence.should == 98
      end

      it "should calculate correct sequences with invalid hash" do
        @second = Deface::Override.new(:virtual_path => "posts/index", :name => "second", :insert_after => "li", :text => "<li>second</li>", :sequence => {})
        @first = Deface::Override.new(:virtual_path => "posts/show", :name => "first", :replace => "li", :text => "<li>first</li>", :sequence => {:before => "second"})

        @second.sequence.should == 100
        @first.sequence.should == 100
      end

    end

    describe "#end_selector" do
      it "should return nil when closing_selector is not defined" do
        @override.end_selector.should be_nil
      end

      it "should return nil when closing_selector is an empty string" do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :closing_selector => "", :text => "<h1>Argh!</h1>")
        @override.end_selector.should be_nil
      end

      it "should return nil when closing_selector is nil" do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :closing_selector => nil, :text => "<h1>Argh!</h1>")
        @override.end_selector.should be_nil
      end

      it "should return combined sibling selector when closing_selector is present" do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :closing_selector => "h4", :text => "<h1>Argh!</h1>")
        @override.end_selector.should == "h1 ~ h4"
      end
    end

    describe "#digest" do
      before { @digest = @override.digest }

      it "should return hex digest based on override's args" do
        @override.digest.should =~ /[a-f0-9]{32}/
      end

      it "should change the digest when any args change" do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h2", :text => "<h1>Argh!</h1>")
        @override.digest.should_not == @digest

        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>")
        @override.digest.should == @digest

        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h2", :text => "<h1>I'm a pirate!</h1>")
        @override.digest.should_not == @digest
      end
    end

    describe "self#digest" do
      before do
        @second = Deface::Override.new(:virtual_path => "posts/index", :name => "second", :insert_after => "p", :text => "<pre>this is code?</pre>")

        @digest = Deface::Override.digest(:virtual_path =>  "posts/index")
      end

      it "should return hex digest based on all applicable overrides" do
        Deface::Override.digest(:virtual_path =>  "posts/index").should =~ /[a-f0-9]{32}/
      end

      it "should change the digest when any args change for any override" do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h2", :text => "<h1>Argh!</h1>")
        Deface::Override.digest(:virtual_path =>  "posts/index").should_not == @digest

        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>")
        Deface::Override.digest(:virtual_path =>  "posts/index").should == @digest

        @second = Deface::Override.new(:virtual_path => "posts/index", :name => "2nd", :insert_after => "p", :text => "<pre>this is code?</pre>")
        Deface::Override.digest(:virtual_path =>  "posts/index").should_not == @digest
      end

      it "should change the digest when overrides are removed / added" do
        Deface::Override.all.clear

        @new_digest = Deface::Override.digest(:virtual_path =>  "posts/index")
        @new_digest.should_not == @digest

        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>")
        Deface::Override.digest(:virtual_path =>  "posts/index").should_not == @new_digest
      end
    end

    describe "#expire_compiled_template" do
      before do
        @compiled_templates = ActionView::CompiledTemplates

        ActionView::CompiledTemplates.instance_methods.each do |method_name|
          ActionView::CompiledTemplates.send :remove_method, method_name
        end
      end

      it "should remove compiled method when method name matches virtual path but not digest" do
        module ActionView::CompiledTemplates
          def _e235fa404c3c2281d4f6791162b1c638_posts_index_123123123
            true #not a real method
          end

          def _f34556de606cec51d4f6791163fab456_posts_edit_123123123
            true #not a real method
          end

        end

        ActionView::CompiledTemplates.instance_methods.size.should == 2
        @override.send(:expire_compiled_template)
        ActionView::CompiledTemplates.instance_methods.size.should == 1
      end

      it "should not remove compiled method when virtual path and digest matach" do

        module ActionView::CompiledTemplates
          def _e235fa404c3c2281d4f6791162b1c638_posts_index_123123123
            true #not a real method
          end
        end

        Deface::Override.should_receive(:digest).and_return('e235fa404c3c2281d4f6791162b1c638')

        ActionView::CompiledTemplates.instance_methods.size.should == 1
        @override.send(:expire_compiled_template)
        ActionView::CompiledTemplates.instance_methods.size.should == 1
      end
    end

  end

end
