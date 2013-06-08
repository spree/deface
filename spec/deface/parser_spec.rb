# encoding: UTF-8
 
require 'spec_helper'

module Deface
  describe Parser do

    describe "#convert" do
      it "should parse html fragment" do
        Deface::Parser.convert("<h1>Hello</h1>").should be_an_instance_of(Nokogiri::HTML::DocumentFragment)
        Deface::Parser.convert("<h1>Hello</h1>").to_s.should == "<h1>Hello</h1>"
        Deface::Parser.convert("<title>Hello</title>").should be_an_instance_of(Nokogiri::HTML::DocumentFragment)
        Deface::Parser.convert("<title>Hello</title>").to_s.should == "<title>Hello</title>"
      end

      it "should parse html document" do
        parsed = Deface::Parser.convert("<html><head><title>Hello</title></head><body>test</body>")
        parsed.should be_an_instance_of(Nokogiri::HTML::Document)
        parsed = parsed.to_s.split("\n")[1..-1] #ignore doctype added by noko

        if RUBY_VERSION < "1.9"
          parsed.should == "<html>\n<head><title>Hello</title></head>\n<body>test</body>\n</html>".split("\n")
        else
          parsed.should == "<html>\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n<title>Hello</title>\n</head>\n<body>test</body>\n</html>".split("\n")
        end

        parsed = Deface::Parser.convert("<html><title>test</title></html>")
        parsed.should be_an_instance_of(Nokogiri::HTML::Document)
        parsed = parsed.to_s.split("\n")[1..-1] #ignore doctype added by noko
        if RUBY_VERSION < "1.9"
          parsed.should == ["<html><head><title>test</title></head></html>"]
        else
          parsed.should == "<html><head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n<title>test</title>\n</head></html>".split("\n")
        end

        parsed = Deface::Parser.convert("<html><p>test</p></html>")
        parsed.should be_an_instance_of(Nokogiri::HTML::Document)
        parsed = parsed.to_s.split("\n")[1..-1] #ignore doctype added by noko
        parsed.should == "<html><body><p>test</p></body></html>".split("\n") 
      end

      it "should parse body tag" do
        parsed = Deface::Parser.convert("<body id=\"body\" <%= something %>>test</body>")
        parsed.should be_an_instance_of(Nokogiri::XML::Element)
        parsed.to_s.should == "<body id=\"body\" data-erb-0=\"&lt;%= something %&gt;\">test</body>"
      end

      it "should convert <% ... %>" do
        Deface::Parser.convert("<% method_name %>").to_s.should == "<code erb-silent> method_name </code>"
      end

      it "should convert <%= ... %>" do
        Deface::Parser.convert("<%= method_name %>").to_s.should == "<code erb-loud> method_name </code>"
      end

      it "should convert first <% ... %> inside html tag" do
        Deface::Parser.convert("<p <% method_name %>></p>").to_s.should == "<p data-erb-0=\"&lt;% method_name %&gt;\"></p>"
      end

      it "should convert second <% ... %> inside html tag" do
        Deface::Parser.convert("<p <% method_name %> <% x = y %>></p>").to_s.should == "<p data-erb-0=\"&lt;% method_name %&gt;\" data-erb-1=\"&lt;% x = y %&gt;\"></p>"
      end

      it "should convert <% ... %> inside double quoted attr value" do
        Deface::Parser.convert("<p id=\"<% method_name %>\"></p>").to_s.should == "<p data-erb-id=\"&lt;% method_name %&gt;\"></p>"
      end

      it "should convert <% ... %> inside single quoted attr value" do
        Deface::Parser.convert("<p id='<% method_name %>'></p>").to_s.should == "<p data-erb-id=\"&lt;% method_name %&gt;\"></p>"
      end

      it "should convert <% ... %> inside non-quoted attr value" do
        Deface::Parser.convert("<p id=<% method_name %>></p>").to_s.should == "<p data-erb-id=\"&lt;% method_name %&gt;\"></p>"
        Deface::Parser.convert("<p id=<% method_name %> alt=\"test\"></p>").to_s.should == "<p data-erb-id=\"&lt;% method_name %&gt;\" alt=\"test\"></p>"
      end

      it "should convert multiple <% ... %> inside html tag" do
        Deface::Parser.convert(%q{<p <%= method_name %> alt="<% x = 'y' + 
                               \"2\" %>" title='<% method_name %>' <%= other_method %></p>}).to_s.should == "<p data-erb-0=\"&lt;%= method_name %&gt;\" data-erb-alt=\"&lt;% x = 'y' + \n                               \\&quot;2\\&quot; %&gt;\" data-erb-title=\"&lt;% method_name %&gt;\" data-erb-1=\"&lt;%= other_method %&gt;\"></p>"
      end

      it "should convert <%= ... %> including href attribute" do
        Deface::Parser.convert(%(<a href="<%= x 'y' + "z" %>">A Link</a>)).to_s.should == "<a data-erb-href=\"&lt;%= x 'y' + &quot;z&quot; %&gt;\">A Link</a>"
      end

      it "should escape contents code tags" do
        Deface::Parser.convert("<% method_name(:key => 'value') %>").to_s.should == "<code erb-silent> method_name(:key =&gt; 'value') </code>"
      end

      it "should respect valid encoding tag" do
        source = %q{<%# encoding: ISO-8859-1 %>Can you say ümlaut?}
        Deface::Parser.convert(source)
        source.encoding.name.should == 'ISO-8859-1'
      end

      it "should force default encoding" do
        source = %q{Can you say ümlaut?}
        source.force_encoding('ISO-8859-1')
        Deface::Parser.convert(source)
        source.encoding.should == Encoding.default_external
      end

      it "should force default encoding" do
        source = %q{<%# encoding: US-ASCII %>Can you say ümlaut?}
        lambda { Deface::Parser.convert(source) }.should raise_error(ActionView::WrongEncodingError)
      end
    end

    describe "#undo_erb_markup" do
      it "should revert <code erb-silent>" do
        Deface::Parser.undo_erb_markup!("<code erb-silent> method_name </code>").should == "<% method_name %>"
      end

      it "should revert <code erb-loud>" do
        Deface::Parser.undo_erb_markup!("<code erb-loud> method_name </code>").should == "<%= method_name %>"
      end

      it "should revert data-erb-x attrs inside html tag" do
        Deface::Parser.undo_erb_markup!("<p data-erb-0=\"&lt;% method_name %&gt;\" data-erb-1=\"&lt;% x = y %&gt;\"></p>").should == "<p <% method_name %> <% x = y %>></p>"
      end

      it "should revert data-erb-id attr inside html tag" do
        Deface::Parser.undo_erb_markup!("<p data-erb-id=\"&lt;% method_name &gt; 1 %&gt;\"></p>").should == "<p id=\"<% method_name > 1 %>\"></p>"
      end

      it "should revert data-erb-href attr inside html tag" do
        Deface::Parser.undo_erb_markup!("<a data-erb-href=\"&lt;%= x 'y' + &quot;z&quot; %&gt;\">A Link</a>").should == %(<a href="<%= x 'y' + \"z\" %>">A Link</a>)
      end

      it "should unescape contents of code tags" do
        Deface::Parser.undo_erb_markup!("<% method(:key =&gt; 'value' %>").should == "<% method(:key => 'value' %>"
        Deface::Parser.undo_erb_markup!("<% method(:key =&gt; 'value'\n %>").should == "<% method(:key => 'value'\n %>"
      end

    end

  end

end
