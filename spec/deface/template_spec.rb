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

    describe "with a single remove override with closing_selector defined" do
      before(:each) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove => "h1", :closing_selector => "h2")
        @template = ActionView::Template.new("<h2>I should be safe</h2><span>Before!</span><h1>start</h1><p>some junk</p><div>more junk</div><h2>end</h2><span>After!</span>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return modified source" do
        @template.source.should == "<h2>I should be safe</h2><span>Before!</span><span>After!</span>"
      end
    end

    describe "with a single replace override defined" do
      before(:each) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "p", :text => "<h1>Argh!</h1>")
        @template = ActionView::Template.new("<p>test</p>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return modified source" do
        @template.source.should == "<h1>Argh!</h1>"
      end
    end

    describe "with a single replace override with closing_selector defined" do
      before(:each) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace => "h1", :closing_selector => "h2", :text => "<span>Argh!</span>")
        @template = ActionView::Template.new("<h1>start</h1><p>some junk</p><div>more junk</div><h2>end</h2>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return modified source" do
        @template.source.should == "<span>Argh!</span>"
      end
    end

    describe "with a single replace_contents override defined" do
      before(:each) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace_contents => "p", :text => "<h1>Argh!</h1>")
        @template = ActionView::Template.new("<p><span>Hello</span>I am not a <em>pirate</em></p>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return modified source" do
        @template.source.should == "<p><h1>Argh!</h1></p>"
      end
    end

    describe "with a single replace_contents override with closing_selector defined" do
      before(:each) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :replace_contents => "h1", :closing_selector => "h2", :text => "<span>Argh!</span>")
        @template = ActionView::Template.new("<h1>start</h1><p>some junk</p><div>more junk</div><h2>end</h2>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return modified source" do
        @template.source.should == "<h1>start</h1><span>Argh!</span><h2>end</h2>"
      end
    end

    describe "with a single insert_after override defined" do
      before(:each) do
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
      before(:each) do
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
      before(:each) do
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

    describe "with a single insert_top override defined when targetted elemenet has no children" do
      before(:each) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_top => "ul", :text => "<li>first</li><li>second</li><li>third</li>")

        @template = ActionView::Template.new("<ul></ul>",
                                             "/path/to/file.erb",
                                             ActionView::Template::Handlers::ERB,
                                             {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return modified source" do
        @template.source.gsub("\n", "").should == "<ul><li>first</li><li>second</li><li>third</li></ul>"
      end
    end

    describe "with a single insert_bottom override defined" do
      before(:each) do
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

    describe "with a single insert_bottom override defined when targetted elemenet has no children" do
      before(:each) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :insert_bottom => "ul", :text => "<li>I'm always last</li>")

        @template = ActionView::Template.new("<ul></ul>",
                                             "/path/to/file.erb",
                                             ActionView::Template::Handlers::ERB,
                                             {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return modified source" do
        @template.source.gsub("\n", "").should == "<ul><li>I'm always last</li></ul>"
      end
    end

    describe "with a single set_attributes override defined" do
      before(:each) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :set_attributes => 'img', 
                                      :attributes => {:class => 'pretty', :alt => 'something interesting'})

        @template = ActionView::Template.new("<div><img class=\"button\" src=\"path/to/button.png\"></div>",
                                             "/path/to/file.erb",
                                             ActionView::Template::Handlers::ERB,
                                             {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return modified source" do
        @template.source.gsub("\n", "").should == "<div><img class=\"pretty\" src=\"path/to/button.png\" alt=\"something interesting\"></div>"
      end
    end


    describe "with a single surround override defined" do
      before(:each) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :surround => "p", :text => "<div></div>")
        @template = ActionView::Template.new("<p>test</p>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return modified source" do
        @template.source.should == "<div><p>test</p></div>"
      end
    end

    describe "with a single surround_contents override defined" do
      before(:each) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :surround_contents => "p", :text => "<span></span>")
        @template = ActionView::Template.new("<p>test</p>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return modified source" do
        @template.source.should == "<p><span>test</span></p>"
      end
    end

    describe "with a single disabled override defined" do
      before(:each) do
        Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :remove => "p", :text => "<h1>Argh!</h1>", :disabled => true)
        @template = ActionView::Template.new("<p>test</p><%= raw(text) %>", "/some/path/to/file.erb", ActionView::Template::Handlers::ERB, {:virtual_path=>"posts/index", :format=>:html})
      end

      it "should return unmodified source" do
        @template.source.should == "<p>test</p><%= raw(text) %>"
      end
    end

    describe "with mulitple sequenced overrides defined" do
      before(:each) do
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
