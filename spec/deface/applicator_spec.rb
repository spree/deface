require 'spec_helper'

def attributes_to_sorted_array(src)
   Nokogiri::HTML::DocumentFragment.parse(src).children.first.attributes
end

module Deface
  describe Applicator do
    include_context "mock Rails.application"
    before { Dummy.all.clear }

    describe "with a single disabled override defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove => "p", :text => "<h1>Argh!</h1>", :disabled => true) }
      let(:source) { "<p>test</p><%= raw(text) %>" }


      it "should return unmodified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<p>test</p><%= raw(text) %>"
      end
    end

    describe "with a single :copy override defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_after => "p", :copy => "h1") }
      let(:source) { "<h1>World</h1><p>Hello</p>" }


      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<h1>World</h1><p>Hello</p><h1>World</h1>"
      end
    end

    describe "with a single :copy using :start and :end" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_before => "h1", 
                                    :copy => {:start => "erb:contains('if true')", :end => "erb:contains('end')"}) }
      let(:source) { "<h1>World</h1><% if true %><p>True that!</p><% end %><p>Hello</p>" }


      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<% if true %><p>True that!</p><% end %><h1>World</h1><% if true %><p>True that!</p><% end %><p>Hello</p>"
      end
    end

    describe "with a single :cut override defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_after => "p", :cut => "h1") }
      let(:source) { "<h1>World</h1><p>Hello</p>" }


      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<p>Hello</p><h1>World</h1>"
      end
    end

    describe "with a single :cut using :start and :end" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", 
                                    :cut => {:start => "erb:contains('if true')", :end => "erb:contains('end')"}) }
      let(:source) { "<h1>World</h1><% if true %><p>True that!</p><% end %><p>Hello</p>" }


      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<% if true %><p>True that!</p><% end %><p>Hello</p>"
      end
    end

    describe "with mulitple sequenced overrides defined" do
      before do
        Deface::Override.new(:virtual_path => "posts/index", :name => "third", :insert_after => "li:contains('second')", :text => "<li>third</li>", :sequence => {:after => "second"})
        Deface::Override.new(:virtual_path => "posts/index", :name => "second", :insert_after => "li", :text => "<li>second</li>", :sequence => {:after => "first"})
        Deface::Override.new(:virtual_path => "posts/index", :name => "first", :replace => "li", :text => "<li>first</li>")
      end

      let(:source) { "<ul><li>replaced</li></ul>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", "").should == "<ul><li>first</li><li>second</li><li>third</li></ul>"
      end
    end

    describe "with incompatible actions and :closing_selector" do
      let(:source) { "<ul><li>first</li><li>second</li><li>third</li></ul>" }

      it "should return modified source" do
        [:insert_before, :insert_after, :insert_top, :insert_bottom, :set_attributes, :remove_from_attributes, :add_to_attributes].each do |action|
          Deface::Override.all.clear
          Deface::Override.new(:virtual_path => "posts/index", :name => "first", action => "li", :closing_selector => "p", :text => "<li>first</li>")

          expect { Dummy.apply(source, {:virtual_path => "posts/index"}) }.to raise_error(Deface::NotSupportedError)
        end
      end
    end

  end
end
