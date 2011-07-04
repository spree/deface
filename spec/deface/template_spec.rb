require 'spec_helper'

module ActionView
  describe Template do
    before(:all) do
      Deface::Override.all.clear
    end

    describe "with no overrides defined" do
      before(:all) do
        @updated_at = Time.now - 600
        @template = ActionView::Template.new("<p>test</p>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html, :updated_at => @updated_at})
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
      before(:all) do
        @updated_at = Time.now - 300
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove => "p", :text => "<h1>Argh!</h1>")
        @template = ActionView::Template.new("<p>test</p><%= raw(text) %>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html, :updated_at => @updated_at})
      end

      it "should return modified source" do
        @template.source.should == "<%= raw(text) %>"
      end

      it "should change updated_at" do
        @template.updated_at.should > @updated_at
      end

    end

    describe "with a single replace override defined" do
      before(:all) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "p", :text => "<h1>Argh!</h1>")
        @template = ActionView::Template.new("<p>test</p>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return modified source" do
        @template.source.should == "<h1>Argh!</h1>"
      end
    end

    describe "with a single insert_after override defined" do
      before(:all) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_after => "img.button", :text => "<% help %>")

        @template = ActionView::Template.new("<div><img class=\"button\" src=\"path/to/button.png\"></div>",
                                             "/path/to/file.erb",
                                             ActionView::Template::Handlers::ERB,
                                             {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return modified source" do
        @template.source.gsub("\n", "").should == "<div><img class=\"button\" src=\"path/to/button.png\"><% help %></div>"
      end
    end

    describe "with a single insert_before override defined" do
      before(:all) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_after => "ul li:last", :text => "<%= help %>")

        @template = ActionView::Template.new("<ul><li>first</li><li>second</li><li>third</li></ul>",
                                             "/path/to/file.erb",
                                             ActionView::Template::Handlers::ERB,
                                             {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return modified source" do
        @template.source.gsub("\n", "").should == "<ul><li>first</li><li>second</li><li>third</li><%= help %></ul>"
      end
    end

    describe "with a single insert_top override defined" do
      before(:all) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_top => "ul", :text => "<li>me first</li>")

        @template = ActionView::Template.new("<ul><li>first</li><li>second</li><li>third</li></ul>",
                                             "/path/to/file.erb",
                                             ActionView::Template::Handlers::ERB,
                                             {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return modified source" do
        @template.source.gsub("\n", "").should == "<ul><li>me first</li><li>first</li><li>second</li><li>third</li></ul>"
      end
    end

    describe "with a single insert_bottom override defined" do
      before(:all) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_bottom => "ul", :text => "<li>I'm always last</li>")

        @template = ActionView::Template.new("<ul><li>first</li><li>second</li><li>third</li></ul>",
                                             "/path/to/file.erb",
                                             ActionView::Template::Handlers::ERB,
                                             {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return modified source" do
        @template.source.gsub("\n", "").should == "<ul><li>first</li><li>second</li><li>third</li><li>I'm always last</li></ul>"
      end
    end


    describe "with a single disabled override defined" do
      before(:all) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove => "p", :text => "<h1>Argh!</h1>", :disabled => true)
        @template = ActionView::Template.new("<p>test</p><%= raw(text) %>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return unmodified source" do
        @template.source.should == "<p>test</p><%= raw(text) %>"
      end
    end


    describe "with mulitple sequenced overrides defined" do
      before(:all) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "third", :insert_after => "li:contains('second')", :text => "<li>third</li>", :sequence => {:after => "second"})
        Deface::Override.new(:virtual_path => "posts/index", :name => "second", :insert_after => "li", :text => "<li>second</li>", :sequence => {:after => "first"})
        Deface::Override.new(:virtual_path => "posts/index", :name => "first", :replace => "li", :text => "<li>first</li>")

        @template = ActionView::Template.new("<ul><li>replaced</li></ul>",
                                             "/path/to/file.erb",
                                             ActionView::Template::Handlers::ERB,
                                             {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return modified source" do
        @template.source.gsub("\n", "").should == "<ul><li>first</li><li>second</li><li>third</li></ul>"
      end
    end

  end
end
