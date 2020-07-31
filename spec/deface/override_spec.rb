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
        expect(@override.action).to eq(action)
      end
    end

    it "should have a sources method" do
      expect(Deface::DEFAULT_SOURCES.map(&:to_sym)).to include(:text)
    end

    it "should return correct selector" do
      expect(@override.selector).to eq("h1")
    end

    it "should set default :updated_at" do
      expect(@override.args[:updated_at]).not_to be_nil
    end

    describe "#original_source" do
      it "should return nil with not specified" do
        expect(@override.original_source).to be_nil
      end

      it "should return parsed nokogiri document when present" do
        @original = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>", :original => "<p><%= something %></p>")
        expect(@original.original_source).to be_an_instance_of Nokogiri::HTML::DocumentFragment

        if RUBY_PLATFORM == 'java'
          expect(@original.original_source.to_s).to eq("<p><erb loud=\"\"> something </erb></p>")
        else
          expect(@original.original_source.to_s).to eq("<p><erb loud> something </erb></p>")
        end
      end
    end

    describe "#validate_original when :original is not present" do
      before(:each) do
        @original = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>")
      end

      it "should warn but not validate" do
        expect(Rails.logger).to receive(:info).once
        expect(@override.validate_original("<p>this gets ignored</p>")).to be_nil
      end

    end

    describe "#validate_original when :original is present" do
      before(:each) do
        @original = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>", :original => "<p><%= something %></p>")
      end

      it "should return true when input contains similar (ignoring whitespace)" do
        if RUBY_PLATFORM == 'java'
          expect( @original.validate_original("<p><erb loud=\"\"> something </erb></p>") ).to eql true
          expect( @original.validate_original("<p><erb loud=\"\">something\n</erb>  </p>") ).to eql true
        else
          expect( @original.validate_original("<p><erb loud> something </erb></p>") ).to eql true
          expect( @original.validate_original("<p><erb loud>something\n</erb>  </p>") ).to eql true
        end
      end

      it  "should return true when input is an array" do
        if RUBY_PLATFORM == 'java'
          expect( @original.validate_original(["<p><erb loud=\"\"> something ","</erb></p>"]) ).to eql true
          expect( @original.validate_original(["<p><erb loud=\"\">something\n","</erb>  </p>"]) ).to eql true
        else
          expect( @original.validate_original(["<p><erb loud> something"," </erb></p>"]) ).to eql true
          expect( @original.validate_original(["<p><erb loud>something\n","</erb>  </p>"]) ).to eql true
        end
      end

      it "should return false when and input contains different string" do
        expect( @original.validate_original("wrong") ).to eql false
      end

      it "should return false with input being an array and is a different string" do
        expect( @original.validate_original(["wrong", "again"]) ).to eql false
      end

    end


    describe "#new" do

      it "should increase all#size by 1" do
        expect {
          Deface::Override.new(:virtual_path => "posts/new", :name => "Posts#new", :replace => "h1", :text => "<h1>argh!</h1>")
        }.to change{Deface::Override.all.size}.by(1)
      end

      it "should default :name when none is given" do
        override = Deface::Override.new(:virtual_path => "posts/new", :replace => "h1", :text => "<h1>Derp!</h1>")
        expect(override.name).not_to be_empty
      end

      it "should default :name to caller's file name and a line number" do
        override = Deface::Override.new(:virtual_path => "posts/new", :replace => "h1", :text => "<h1>Derp!</h1>")
        expect(override.name).to match Regexp.new("#{Regexp.escape(File.basename(__FILE__, '.rb'))}_\\d+")
      end

      it "should use :name argument when given" do
        name = "Posts#new"
        override = Deface::Override.new(:virtual_path => "posts/new", :name => name, :replace => "h1", :text => "<h1>Derp!</h1>")
        expect(override.name).to eq(name)
      end
    end

    describe "with :text" do

      before(:each) do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1 id=\"<%= dom_id @pirate %>\">Argh!</h1>")
      end

      it "should return un-convert text as source" do
        expect(@override.source).to eq("<h1 id=\"<%= dom_id @pirate %>\">Argh!</h1>")

        expect(@override.source_argument).to eq(:text)
      end
    end

    describe "with :erb" do

      before(:each) do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :erb => "<h1 id=\"<%= dom_id @pirate %>\">Argh!</h1>")
      end

      it "should return un-convert text as source" do
        expect(@override.source).to eq("<h1 id=\"<%= dom_id @pirate %>\">Argh!</h1>")

        expect(@override.source_argument).to eq(:erb)
      end
    end

    describe "with :haml" do

      before(:each) do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1",
                                         :haml => %q{%strong{:class => "erb", :id => "message"}= 'Hello, World!'})
      end

      it "should return erb converted from haml as source" do
        expect(@override.source).to eq("<strong class='erb' id='message'><%= 'Hello, World!' %></strong>\n")

        expect(@override.source_argument).to eq(:haml)
      end
    end

    describe "with :slim" do

      before(:each) do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1",
                                         :slim => %q{strong class="erb" id="message"= 'Hello, World!'})
      end

      it "should return erb converted from slim as source" do
        expect(@override.source).to eq("<strong class=\"erb\" id=\"message\"><%= ::Temple::Utils.escape_html_safe(('Hello, World!')) %>\n</strong>")

        expect(@override.source_argument).to eq(:slim)
      end
    end


    describe "with :partial containing erb" do

      before(:each) do
        #stub view paths to be local spec/assets directory
        allow(ActionController::Base).to receive(:view_paths).and_return([File.join(File.dirname(__FILE__), '..', "assets")])

        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :partial => "shared/post")
      end

      it "should return un-convert partial contents as source" do
        expect(@override.source).to eq("<p>I'm from shared/post partial</p>\n<%= \"And I've got ERB\" %>\n")

        expect(@override.source_argument).to eq(:partial)
      end

    end

    describe "with :template" do

      before(:each) do
        #stub view paths to be local spec/assets directory
        allow(ActionController::Base).to receive(:view_paths).and_return([File.join(File.dirname(__FILE__), '..', "assets")])

        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :template => "shared/person")
      end

      it "should return un-convert template contents as source" do
        expect(@override.source).to eq("<p>I'm from shared/person template</p>\n<%= \"I've got ERB too\" %>\n")

        expect(@override.source_argument).to eq(:template)
      end

    end

    describe "with :copy" do

      let(:parsed) { Deface::Parser.convert("<div><h1>Manage Posts</h1><%= some_method %></div>") }

      before(:each) do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_after => "h1", :copy => "h1")
        allow(@override).to receive(:parsed_document).and_return(parsed)
      end

      it "should not change original parsed source" do
        @override.source

        if RUBY_PLATFORM == 'java'
          expect(parsed.to_s.gsub(/\n/,'')).to eq("<div><h1>Manage Posts</h1><erb loud=\"\"> some_method </erb></div>")
        else
          expect(parsed.to_s.gsub(/\n/,'')).to eq("<div><h1>Manage Posts</h1><erb loud> some_method </erb></div>")
        end

        expect(@override.source_argument).to eq(:copy)
      end

      it "should return copy of content from source document" do
        expect(@override.source.to_s.strip).to eq("<h1>Manage Posts</h1>")
      end

      it "should return unescaped content for source document" do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_after => "h1", :copy => "erb[loud]:contains('some_method')")
        allow(@override).to receive(:parsed_document).and_return(parsed)
        expect(@override.source).to eq("<%= some_method %>")
      end

    end

    describe "with :copy using :start and :end" do

      let(:parsed) { Deface::Parser.convert("<h1>World</h1><% if true %><p>True that!</p><% end %><p>Hello</p>") }

      before(:each) do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_after => "h1",
                                         :copy => {:start => "erb:contains('if true')", :end => "erb:contains('end')"})

        allow(@override).to receive(:parsed_document).and_return(parsed)
      end

      it "should not change original parsed source" do
        @override.source

        if RUBY_PLATFORM == 'java'
          expect(parsed.to_s.gsub(/\n/,'')).to eq("<h1>World</h1><erb silent=\"\"> if true </erb><p>True that!</p><erb silent=\"\"> end </erb><p>Hello</p>")
        else
          expect(parsed.to_s.gsub(/\n/,'')).to eq("<h1>World</h1><erb silent> if true </erb><p>True that!</p><erb silent> end </erb><p>Hello</p>")
        end

        expect(@override.source_argument).to eq(:copy)
      end

      it "should return copy of content from source document" do
        expect(@override.source).to eq("<% if true %><p>True that!</p><% end %>")
      end
    end

    describe "with :cut" do
      let(:parsed) { Deface::Parser.convert("<div><h1>Manage Posts</h1><%= some_method %></div>") }
      before(:each) do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_after => "h1", :cut => "h1")
        allow(@override).to receive(:parsed_document).and_return(parsed)
      end

      it "should remove cut element from original parsed source" do
        @override.source
        if RUBY_PLATFORM == 'java'
          expect(parsed.to_s.gsub(/\n/,'')).to eq("<div><erb loud=\"\"> some_method </erb></div>")
        else
          expect(parsed.to_s.gsub(/\n/,'')).to eq("<div><erb loud> some_method </erb></div>")
        end

        expect(@override.source_argument).to eq(:cut)
      end

      it "should remove and return content from source document" do
        expect(@override.source).to eq("<h1>Manage Posts</h1>")
      end

      it "should return unescaped content for source document" do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_after => "h1", :cut => "erb[loud]:contains('some_method')")
        allow(@override).to receive(:parsed_document).and_return(parsed)
        expect(@override.source).to eq("<%= some_method %>")
      end

    end


    describe "with :cut using :start and :end" do

      let(:parsed) { Deface::Parser.convert("<h1>World</h1><% if true %><p>True that!</p><% end %><%= hello %>") }

      before(:each) do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_after => "h1",
                                         :cut => {:start => "erb:contains('if true')", :end => "erb:contains('end')"})

        allow(@override).to receive(:parsed_document).and_return(parsed)
      end

      it "should remove cut element from original parsed source" do
        @override.source
        if RUBY_PLATFORM == 'java'
          expect(parsed.to_s.gsub(/\n/,'')).to eq("<h1>World</h1><erb loud=\"\"> hello </erb>")
        else
          expect(parsed.to_s.gsub(/\n/,'')).to eq("<h1>World</h1><erb loud> hello </erb>")
        end

        expect(@override.source_argument).to eq(:cut)
      end

      it "should return copy of content from source document" do
        expect(@override.source).to eq("<% if true %><p>True that!</p><% end %>")
      end
    end

    describe "with block" do
      before(:each) do
        #stub view paths to be local spec/assets directory
        allow(ActionController::Base).to receive(:view_paths).and_return([File.join(File.dirname(__FILE__), '..', "assets")])

        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1") do
          "This is replacement text for the h1"
        end
      end

      it "should set source to block content" do
        expect(@override.source).to eq("This is replacement text for the h1")
      end
    end

    describe "with :namespaced" do
      before(:each) do
        Deface::Override.current_railtie = 'SpreeEngine'
        @override = Deface::Override.new(:virtual_path => 'sample_path', :name => 'sample_name', :replace => 'h1', :namespaced => true)
      end

      it "should namespace the override's name" do
        expect(@override.name).to eq('spree_engine_sample_name')
      end
    end

    describe "with global namespaced option set to true" do
      before(:each) do
        Deface::Override.current_railtie = 'SpreeEngine'
        Rails.application.config.deface.namespaced = true
        @override = Deface::Override.new(:virtual_path => 'sample_path', :name => 'sample_name', :replace => 'h1')
      end

      it "should namespace the override's name" do
        expect(@override.name).to eq('spree_engine_sample_name')
      end
    end

    describe "#source_element" do
      before(:each) do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<%= method :opt => 'x' & 'y' %>")
      end

      it "should return escaped source" do
        expect(@override.source_element).to be_an_instance_of Nokogiri::HTML::DocumentFragment

        if RUBY_PLATFORM == 'java'
          source = "<erb loud=\"\"> method :opt =&gt; 'x' &amp; 'y' </erb>"
          expect(@override.source_element.to_s).to eq(source)
          #do it twice to ensure it doesn't change as it's destructive
          expect(@override.source_element.to_s).to eq(source)
        else
          source = "<erb loud> method :opt =&gt; 'x' &amp; 'y' </erb>"
          expect(@override.source_element.to_s).to eq(source)
          #do it twice to ensure it doesn't change as it's destructive
          expect(@override.source_element.to_s).to eq(source)
        end
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
        expect(@replacement.source).not_to eq("<h1>Argh!</h1>")
        expect(@replacement.source).to eq("<h1>Arrrr!</h1>")
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
        expect(@replacement.action).to eq(:insert_after)
      end

      it "should remove old action" do
        expect( @replacement.args.has_key?(:replace)).to eql false
      end

    end

    describe "when redefining an override when changing source type" do
      before(:each) do
        #stub view paths to be local spec/assets directory
        allow(ActionController::Base).to receive(:view_paths).and_return([File.join(File.dirname(__FILE__), '..', "assets")])

        Rails.application.config.deface.overrides.all.clear
        @override    = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :partial => "shared/post", :replace => "h1", :text => "<span>I'm text</span>")
        expect {
          @replacement = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :erb => "<p>I do be a pirate!</p>")
        }.to change{Rails.application.config.deface.overrides.all.size}.by(0)
      end

      it "should return new source" do
        expect(@override.source).to eq("<p>I do be a pirate!</p>")
      end

    end


    describe "#sequence" do
      it "should calculate correct after sequences" do
        @third = Deface::Override.new(:virtual_path => "posts/index", :name => "third", :insert_after => "li:contains('second')", :text => "<li>third</li>", :sequence => {:after => "second"})
        @second = Deface::Override.new(:virtual_path => "posts/index", :name => "second", :insert_after => "li", :text => "<li>second</li>", :sequence => {:after => "first"})
        @first = Deface::Override.new(:virtual_path => "posts/index", :name => "first", :replace => "li", :text => "<li>first</li>")

        expect(@third.sequence).to eq(102)
        expect(@second.sequence).to eq(101)
        expect(@first.sequence).to eq(100)
      end

      it "should calculate correct before sequences" do
        @second = Deface::Override.new(:virtual_path => "posts/index", :name => "second", :insert_after => "li", :text => "<li>second</li>", :sequence => 99)
        @first = Deface::Override.new(:virtual_path => "posts/index", :name => "first", :replace => "li", :text => "<li>first</li>", :sequence => {:before => "second"})

        expect(@second.sequence).to eq(99)
        expect(@first.sequence).to eq(98)
      end

      it "should calculate correct sequences with invalid hash" do
        @second = Deface::Override.new(:virtual_path => "posts/index", :name => "second", :insert_after => "li", :text => "<li>second</li>", :sequence => {})
        @first = Deface::Override.new(:virtual_path => "posts/show", :name => "first", :replace => "li", :text => "<li>first</li>", :sequence => {:before => "second"})

        expect(@second.sequence).to eq(100)
        expect(@first.sequence).to eq(100)
      end

    end

    describe "#end_selector" do
      it "should return nil when closing_selector is not defined" do
        expect(@override.end_selector).to be_nil
      end

      it "should return nil when closing_selector is an empty string" do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :closing_selector => "", :text => "<h1>Argh!</h1>")
        expect(@override.end_selector).to be_nil
      end

      it "should return nil when closing_selector is nil" do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :closing_selector => nil, :text => "<h1>Argh!</h1>")
        expect(@override.end_selector).to be_nil
      end

      it "should return closing_selector is present" do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :closing_selector => "h4", :text => "<h1>Argh!</h1>")
        expect(@override.end_selector).to eq("h4")
      end
    end

    describe "#touch" do
      it "should change the overrides :updated_at value" do
        before_touch = @override.args[:updated_at]
        allow(Time.zone).to receive(:now).and_return(Time.parse('2006-08-24'))
        @override.touch
        expect(@override.args[:updated_at]).not_to eq(before_touch)
      end
    end

    describe "#digest" do
      before do
        Deface::Override.all.clear

        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>")
        @digest = @override.digest.clone
      end

      it "should return hex digest based on override's args" do
        expect(@override.digest).to match(/[a-f0-9]{32}/)
      end

      it "should change the digest when any args change" do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h2", :text => "<h1>Argh!</h1>")
        expect(@override.digest).not_to eq(@digest)

        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>")
        expect(@override.digest).to eq(@digest)

        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h2", :text => "<h1>I'm a pirate!</h1>")
        expect(@override.digest).not_to eq(@digest)
      end
    end

    describe "self#digest" do
      before do
        Deface::Override.all.clear

        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>")
        @second = Deface::Override.new(:virtual_path => "posts/index", :name => "second", :insert_after => "p", :text => "<pre>this is erb?</pre>")

        @digest = Deface::Override.digest(:virtual_path =>  "posts/index")
      end

      it "should return hex digest based on all applicable overrides" do
        expect(Deface::Override.digest(:virtual_path =>  "posts/index")).to match(/[a-f0-9]{32}/)
      end

      it "should change the digest when any args change for any override" do
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h2", :text => "<h1>Argh!</h1>")
        expect(Deface::Override.digest(:virtual_path =>  "posts/index")).not_to eq(@digest)

        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>")
        expect(Deface::Override.digest(:virtual_path =>  "posts/index")).to eq(@digest)

        @second = Deface::Override.new(:virtual_path => "posts/index", :name => "2nd", :insert_after => "p", :text => "<pre>this is erb?</pre>")
        expect(Deface::Override.digest(:virtual_path =>  "posts/index")).not_to eq(@digest)
      end

      it "should change the digest when overrides are removed / added" do
        Deface::Override.all.clear

        @new_digest = Deface::Override.digest(:virtual_path =>  "posts/index")
        expect(@new_digest).not_to eq(@digest)

        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>")
        expect(Deface::Override.digest(:virtual_path =>  "posts/index")).not_to eq(@new_digest)
      end
    end

    describe "#expire_compiled_template" do
      it "should remove compiled method when method name matches virtual path but not digest" do
        if Deface.before_rails_6?
          instance_methods_count = ActionView::CompiledTemplates.instance_methods.size

          module ActionView::CompiledTemplates
            def _e235fa404c3c2281d4f6791162b1c638_posts_index_123123123
              true #not a real method
            end

            def _f34556de606cec51d4f6791163fab456_posts_edit_123123123
              true #not a real method
            end
          end

          expect(ActionView::CompiledTemplates.instance_methods.size).to eq(instance_methods_count + 2)
          @override.send(:expire_compiled_template)
          expect(ActionView::CompiledTemplates.instance_methods.size).to eq(instance_methods_count + 1)

        else
          instance_methods_count = ActionDispatch::DebugView.instance_methods.size

          class ActionDispatch::DebugView
            def _e235fa404c3c2281d4f6791162b1c638_posts_index_123123123
              true #not a real method
            end

            def _f34556de606cec51d4f6791163fab456_posts_edit_123123123
              true #not a real method
            end
          end

          expect(ActionDispatch::DebugView.instance_methods.size).to eq(instance_methods_count + 2)
          @override.send(:expire_compiled_template)
          expect(ActionDispatch::DebugView.instance_methods.size).to eq(instance_methods_count + 1)
        end
      end

      it "should not remove compiled method when virtual path and digest matach" do
        if Deface.before_rails_6?
          instance_methods_count = ActionView::CompiledTemplates.instance_methods.size

          module ActionView::CompiledTemplates
            def _e235fa404c3c2281d4f6791162b1c638_posts_index_123123123
              true #not a real method
            end
          end

          expect(Deface::Override).to receive(:digest).and_return('e235fa404c3c2281d4f6791162b1c638')

          expect(ActionView::CompiledTemplates.instance_methods.size).to eq(instance_methods_count + 1)
          @override.send(:expire_compiled_template)
          expect(ActionView::CompiledTemplates.instance_methods.size).to eq(instance_methods_count + 1)

        else
          instance_methods_count = ActionDispatch::DebugView.instance_methods.size

          class ActionDispatch::DebugView
            def _e235fa404c3c2281d4f6791162b1c638_posts_index_123123123
              true #not a real method
            end
          end

          expect(Deface::Override).to receive(:digest).and_return('e235fa404c3c2281d4f6791162b1c638')

          expect(ActionDispatch::DebugView.instance_methods.size).to eq(instance_methods_count + 1)
          @override.send(:expire_compiled_template)
          expect(ActionDispatch::DebugView.instance_methods.size).to eq(instance_methods_count + 1)
        end
      end
    end

  end

end
