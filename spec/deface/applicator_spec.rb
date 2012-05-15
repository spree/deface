require 'spec_helper'

class Dummy
  extend Deface::Applicator::ClassMethods
  extend Deface::Search::ClassMethods

  def self.all
    Rails.application.config.deface.overrides.all
  end
end


def attributes_to_sorted_array(src)
   Nokogiri::HTML::DocumentFragment.parse(src).children.first.attributes
end

module Deface
  describe Applicator do
    include_context "mock Rails.application"
    before { Dummy.all.clear }

    describe "with a single remove override defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove => "p", :text => "<h1>Argh!</h1>") }
      let(:source) { "<p>test</p><%= raw(text) %>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<%= raw(text) %>"
      end

    end

    describe "with a single remove override with closing_selector defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove => "h1", :closing_selector => "h2") }
      let(:source) { "<h2>I should be safe</h2><span>Before!</span><h1>start</h1><p>some junk</p><div>more junk</div><h2>end</h2><span>After!</span>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<h2>I should be safe</h2><span>Before!</span><span>After!</span>"
      end
    end

    describe "with a single replace override defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "p", :text => "<h1>Argh!</h1>") }
      let(:source) { "<p>test</p>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should  == "<h1>Argh!</h1>"
      end
    end

    describe "with a single replace override with closing_selector defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :closing_selector => "h2", :text => "<span>Argh!</span>") }
      let(:source) { "<h1>start</h1><p>some junk</p><div>more junk</div><h2>end</h2>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<span>Argh!</span>"
      end
    end

    describe "with a single replace_contents override defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace_contents => "p", :text => "<h1>Argh!</h1>") }
      let(:source) { "<p><span>Hello</span>I am not a <em>pirate</em></p>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<p><h1>Argh!</h1></p>"
      end
    end

    describe "with a single replace_contents override with closing_selector defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace_contents => "h1", :closing_selector => "h2", :text => "<span>Argh!</span>") }
      let(:source) { "<h1>start</h1><p>some junk</p><div>more junk</div><h2>end</h2>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<h1>start</h1><span>Argh!</span><h2>end</h2>"
      end
    end

    describe "with a single insert_after override defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_after => "img.button", :text => "<% help %>") }
      let(:source) { "<div><img class=\"button\" src=\"path/to/button.png\"></div>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", "").should == "<div><img class=\"button\" src=\"path/to/button.png\"><% help %></div>"
      end
    end

    describe "with a single insert_before override defined" do
      before  { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_after => "ul li:last", :text => "<%= help %>") }
      let(:source) { "<ul><li>first</li><li>second</li><li>third</li></ul>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", "").should == "<ul><li>first</li><li>second</li><li>third</li><%= help %></ul>"
      end
    end

    describe "with a single insert_top override defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_top => "ul", :text => "<li>me first</li>") }
      let(:source) { "<ul><li>first</li><li>second</li><li>third</li></ul>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", "").should == "<ul><li>me first</li><li>first</li><li>second</li><li>third</li></ul>"
      end
    end

    describe "with a single insert_top override defined when targetted elemenet has no children" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_top => "ul", :text => "<li>first</li><li>second</li><li>third</li>") }
      let(:source) { "<ul></ul>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", "").should == "<ul><li>first</li><li>second</li><li>third</li></ul>"
      end
    end

    describe "with a single insert_bottom override defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_bottom => "ul", :text => "<li>I'm always last</li>") }
      let(:source) { "<ul><li>first</li><li>second</li><li>third</li></ul>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", "").should == "<ul><li>first</li><li>second</li><li>third</li><li>I'm always last</li></ul>"
      end
    end

    describe "with a single insert_bottom override defined when targetted elemenet has no children" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_bottom => "ul", :text => "<li>I'm always last</li>") }
      let(:source) { "<ul></ul>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", "").should == "<ul><li>I'm always last</li></ul>"
      end
    end

    describe "with a single set_attributes override (containing only text) defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :set_attributes => 'img', 
                                      :attributes => {:class => 'pretty', :alt => 'something interesting'}) }
      let(:source) { "<img class=\"button\" src=\"path/to/button.png\">" }

      it "should return modified source" do
        attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

        attrs["class"].value.should == "pretty"
        attrs["alt"].value.should == "something interesting"
        attrs["src"].value.should == "path/to/button.png"
      end
    end

    describe "with a single set_attributes override (containing erb) defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :set_attributes => 'img', 
                                      :attributes => {:class => 'pretty', 'data-erb-alt' => '<%= something_interesting %>'}) }
      let(:source) { "<img class=\"button\" src=\"path/to/button.png\">" }

      it "should return modified source" do
        attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

        attrs["class"].value.should == "pretty"
        attrs["alt"].value.should == "<%= something_interesting %>"
        attrs["src"].value.should == "path/to/button.png"
      end
    end

    describe "with a single set_attributes override (containing erb) defined targetting an existing pseudo attribute" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :set_attributes => 'img', 
                                      :attributes => {:class => '<%= get_some_other_class %>', :alt => 'something interesting'}) }
      let(:source) { "<img class=\"<%= get_class %>\" src=\"path/to/button.png\">" }

      it "should return modified source" do
        attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

        attrs["class"].value.should == "<%= get_some_other_class %>"
        attrs["alt"].value.should == "something interesting"
        attrs["src"].value.should == "path/to/button.png"
      end
    end

    describe "with a single add_to_attributes override (containing only text) defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :add_to_attributes => 'img', 
                                      :attributes => {:class => 'pretty', :alt => 'something interesting'}) }
      let(:source) { "<img class=\"button\" src=\"path/to/button.png\">" }

      it "should return modified source" do
        attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

        attrs["class"].value.should == "button pretty"
        attrs["alt"].value.should == "something interesting"
      end
    end

    describe "with a single add_to_attributes override (containing erb) defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :add_to_attributes => 'img', 
                                      :attributes => {:class => '<%= add_class %>'}) }
      let(:source) { "<img class=\"button\" src=\"path/to/button.png\">" }

      it "should return modified source" do
        attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

        attrs["class"].value.should == "button <%= add_class %>"
        attrs["src"].value.should == "path/to/button.png"
      end
    end

    describe "with a single add_to_attributes override (containing erb) defined using pseudo attribute name" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :add_to_attributes => 'img', 
                                      :attributes => {'data-erb-class' => '<%= add_class %>'}) }
      let(:source) { "<img class=\"button\" src=\"path/to/button.png\">" }

      it "should return modified source" do
        attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

        attrs["class"].value.should == "button <%= add_class %>"
        attrs["src"].value.should == "path/to/button.png"
      end
    end

    describe "with a single add_to_attributes override (containing erb) defined targetting an existing pseudo attribute" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :add_to_attributes => 'img', 
                                      :attributes => {:class => '<%= get_some_other_class %>'}) }
      let(:source) { "<img class=\"<%= get_class %>\" src=\"path/to/button.png\">" }

      it "should return modified source" do
        attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

        attrs["class"].value.should == "<%= get_class %> <%= get_some_other_class %>"
        attrs["src"].value.should == "path/to/button.png"
      end
    end

    describe "with a single remove_from_attributes override (containing only text) defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove_from_attributes => 'img', 
                                      :attributes => {:class => 'pretty'}) }
      let(:source) { "<img class=\"pretty button\" src=\"path/to/button.png\">" }

      it "should return modified source" do
        attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

        attrs["class"].value.should == "button"
      end
    end

    describe "with a single remove_from_attributes override (containing erb) defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove_from_attributes => 'img', 
                                      :attributes => {:class => '<%= add_class %>'}) }
      let(:source) { "<img class=\"button <%= add_class %>\" src=\"path/to/button.png\">" }

      it "should return modified source" do
        attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

        attrs["class"].value.should == "button"
        attrs["src"].value.should == "path/to/button.png"
      end
    end

    describe "with a single remove_from_attributes override (containing erb) defined using pseudo attribute name" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove_from_attributes => 'img', 
                                      :attributes => {'data-erb-class' => '<%= add_class %>'}) }
      let(:source) { "<img class=\"button <%= add_class %>\" src=\"path/to/button.png\">" }

      it "should return modified source" do
        attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

        attrs["class"].value.should == "button"
        attrs["src"].value.should == "path/to/button.png"
      end
    end

    describe "with a single remove_from_attributes override (containing only text) defined where value is not present in attribute" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove_from_attributes => 'img', 
                                      :attributes => {:class => 'pretty'}) }
      let(:source) { "<img class=\"button\" src=\"path/to/button.png\">" }

      it "should return unmodified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<img class=\"button\" src=\"path/to/button.png\">" 
      end
    end

    describe "with a single remove_from_attributes override (containing only text) defined where value is not present in attribute" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove_from_attributes => 'img', 
                                      :attributes => {:class => 'pretty'}) }
      let(:source) { "<img src=\"path/to/button.png\">" }

      it "should return unmodified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<img src=\"path/to/button.png\">" 
      end
    end

    describe "with a single remove_from_attributes override (containing erb) defined targetting an existing pseudo attribute" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove_from_attributes => 'img', 
                                      :attributes => {:class => '<%= get_some_other_class %>'}) }
      let(:source) { "<img class=\"<%= get_class %> <%= get_some_other_class %>\" src=\"path/to/button.png\">" }

      it "should return modified source" do
        attrs = attributes_to_sorted_array(Dummy.apply(source, {:virtual_path => "posts/index"}))

        attrs["class"].value.should == "<%= get_class %>"
        attrs["src"].value.should == "path/to/button.png"
      end
    end

    describe "with a single set_attributes override (containing a pseudo attribute with erb) defined targetting an existing pseudo attribute" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :set_attributes => 'img', 
                                      :attributes => {'class' => '<%= hello_world %>'}) }
      let(:source) { "<div><img class=\"<%= hello_moon %>\" src=\"path/to/button.png\"></div>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", "").should == "<div><img src=\"path/to/button.png\" class=\"<%= hello_world %>\"></div>"
      end
    end

    describe "with a single html surround override defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :surround => "p", :text => "<h1>It's behind you!</h1><div><%= render_original %></div>") }
      let(:source) { "<p>test</p>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<h1>It's behind you!</h1><div><p>test</p></div>"
      end
    end

    describe "with a single erb surround override defined" do
      before  { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :surround => "p", :text => "<% some_method('test') do %><%= render_original %><% end %>") }
      let(:source) { "<span><p>test</p></span>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", '').should == "<span><% some_method('test') do %><p>test</p><% end %></span>"
      end
    end

    describe "with a single html surround_contents override defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :surround_contents => "div", :text => "<span><%= render_original %></span>") }
      let(:source) { "<h4>yay!</h4><div><p>test</p></div>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<h4>yay!</h4><div><span><p>test</p></span></div>"
      end
    end

    describe "with a single erb surround_contents override defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :surround_contents => "p", :text => "<% if 1==1 %><%= render_original %><% end %>") }
      let(:source) { "<p>test</p>" }

      it "should return modified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<p><% if 1==1 %>test<% end %></p>"
      end
    end

    describe "with a single disabled override defined" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove => "p", :text => "<h1>Argh!</h1>", :disabled => true) }
      let(:source) { "<p>test</p><%= raw(text) %>" }


      it "should return unmodified source" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<p>test</p><%= raw(text) %>"
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

    describe "with a single move_bottom override" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :move_bottom => "child", :to => "parent") }
      let(:source) { '<child>move me</child><parent>destination</parent>' }

      it "should return modified source, with element moved" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<parent>destination<child>move me</child></parent>"
      end
    end

    describe "with a single move_top override" do
      before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :move_top => "child", :to => "parent") }
      let(:source) { '<child>move me</child><parent>destination</parent>' }

      it "should return modified source, with element moved" do
        Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<parent><child>move me</child>destination</parent>"
      end
    end

  end
end
