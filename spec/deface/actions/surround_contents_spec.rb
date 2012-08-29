require 'spec_helper'

module Deface
  module Actions
    describe SurroundContents do
      include_context "mock Rails.application"
      before { Dummy.all.clear }

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

      describe "with a single erb surround_contents override defined using :closing_selector" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :surround_contents => "h1", :closing_selector => "p",
                                      :text => "<% if 1==1 %><%= render_original %><% end %>") }
        let(:source) { "<div><h1>Start</h1><h2>middle</h2><h3>child</h3><p><span>This is the</span> end.</p></div>" }

        it "should return modified source" do
          Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", '').should == "<div><h1>Start</h1><% if 1==1 %><h2>middle</h2><h3>child</h3><% end %><p><span>This is the</span> end.</p></div>"
        end
      end

      describe "with multiple render_original calls defined" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :surround_contents => "p", :text => "<% if 1==1 %><%= render_original %><% else %><%= render_original %><% end %>") }
        let(:source) { "<p>test</p>" }

        it "should return modified source" do
          Dummy.apply(source, {:virtual_path => "posts/index"}).should == "<p><% if 1==1 %>test<% else %>test<% end %></p>"
        end
      end

      describe "with multiple render_original calls defined using :closing_selector" do
        before { Deface::Override.new(:virtual_path => "posts/index", :name => "Posts#index", :surround_contents => "h1", :closing_selector => "p",
                                      :text => "<% if 1==1 %><%= render_original %><% else %><%= render_original %><% end %>") }
        let(:source) { "<div><h1>Start</h1><h2>middle</h2><h3>child</h3><p><span>This is the</span> end.</p></div>" }

        it "should return modified source" do
          Dummy.apply(source, {:virtual_path => "posts/index"}).gsub("\n", '').should == "<div><h1>Start</h1><% if 1==1 %><h2>middle</h2><h3>child</h3><% else %><h2>middle</h2><h3>child</h3><% end %><p><span>This is the</span> end.</p></div>"
        end
      end
    end
  end
end
