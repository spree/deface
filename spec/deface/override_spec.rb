require 'spec_helper'

module Deface
  describe Override do
    before(:each) do
      @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>")
    end

    it "should return correct action" do
      Deface::Override.actions.each do |action|
        @override = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", action => "h1", :text => "<h1>Argh!</h1>")
        @override.action.should == action
      end
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

    describe "#validate_original" do
      before(:each) do
        @original = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Argh!</h1>", :original => "<p><%= something %></p>")
      end

      it "should return true when :original is not present" do
        @override.validate_original("").should be_true
      end

      it "should return true when :original present, and input contains similar (ignoring whitespace)" do
        @original.validate_original("<p><code erb-loud> something </code></p>").should be_true
        @original.validate_original("<p><code erb-loud>something\n</code>  </p>").should be_true
      end

      it "should return false when :original present, and input contains different string" do
        @original.validate_original("wrong").should be_false
      end
    end

    describe "#find" do
      it "should find by virtual_path" do
        Deface::Override.find({:virtual_path => "posts/index"}).size.should == 1
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

    describe "with :partial" do

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

    describe "when redefining an existing virutal_path and name" do
      before(:each) do
        @replacement = Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Arrrr!</h1>")
      end

      it "should not increase all#size by 1" do
        expect {
          Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :text => "<h1>Arrrr!</h1>")
        }.to change{Deface::Override.all.size}.by(0)

      end

      it "should return new source" do
        @replacement.source.should_not == @override.source
        @replacement.source.should == "<h1>Arrrr!</h1>"
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

  end

end
