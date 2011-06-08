Deface
======

Deface is a library that allows you to customize ERB views in a Rails application without editing the underlying view.

It allows you to easily target html & erb elements as the hooks for customization using CSS selectors as supported by Nokogiri.

Demo & Testing
---------------
You can play with Deface and see its parsing in action at [deface.heroku.com](http://deface.heroku.com)


Deface::Override
=======

A new instance of the Deface::Override class is initialized for each customization you wish to define. When initializing a new override you must supply only one Target, Action & Source parameter and any number of Optional parameters. Note: the source parameter is not required when the "remove" action is specified.

Target
------
* <tt>:virtual_path</tt> - The template / partial / layout where the override should take effect eg: *"shared/_person"*, *"admin/posts/new"* this will apply to all controller actions that use the specified template.

Action
------
* <tt>:remove</tt> - Removes all elements that match the supplied selector

* <tt>:replace</tt> - Replaces all elements that match the supplied selector

* <tt>:insert_after</tt> - Inserts after all elements that match the supplied selector

* <tt>:insert_before</tt> - Inserts before all elements that match the supplied selector

* <tt>:insert_top</tt> - Inserts inside all elements that match the supplied selector, as the first child.

* <tt>:insert_bottom</tt> - Inserts inside all elements that match the supplied selector, as the last child.

Source
------
* <tt>:text</tt> - String containing markup

* <tt>:partial</tt> - Relative path to a partial

* <tt>:template</tt> - Relative path to a template


Optional
--------
* <tt>:name</tt> - Unique name for override so it can be identified and modified later. This needs to be unique within the same `:virtual_path`

* <tt>:disabled</tt> - When set to true the override will not be applied.

* <tt>:original</tt> - String containing original markup that is being overridden. If supplied Deface will log when the original markup changes, which helps highlight overrides that need attention when upgrading versions of the source application. Only really warranted for :replace overrides. NB: All whitespace is stripped before comparsion.

Examples
========

Replaces all instances of _h1_ in the `posts/_form.html.erb` partial with `<h1>New Post</h1>`

     Deface::Override.new(:virtual_path => "posts/_form", 
                          :name => "example-1", 
                          :replace => "h1", 
                          :text => "<h1>New Post</h1>")

Inserts `<%= link_to "List Comments", comments_url(post) %>` before all instances of `p` with css class `comment` in `posts/index.html.erb`

     Deface::Override.new(:virtual_path => "posts/index", 
                          :name => "example-2", 
                          :insert_before => "p.comment",
                          :text => "<%= link_to "List Comments", comments_url(post) %>")

Inserts the contents of `shared/_comment.html.erb` after all instances of `div` with an id of `comment_21` in `posts/show.html.erb`

     Deface::Override.new(:virtual_path => "posts/show", 
                          :name => "example-3",
                          :insert_after => "div#comment_21", 
                          :partial => "shared/comment")

Removes any ERB block containing the string `helper_method` in the `posts/new.html.erb` template, will also log if markup being removed does not match `<%= helper_method %>`

     Deface::Override.new(:virtual_path => "posts/new", 
                          :name => "example-4", 
                          :remove => "code[erb-loud]:contains('helper_method')",
                          :original => "<%= helper_method %>")


Implementation
==============

Deface temporarily converts ERB files into a pseudo HTML markup that can be parsed and queired by Nokogiri, using the following approach:

    <%= some ruby code %> 

     becomes 

    <code erb-loud> some ruby code </code>

and 
  
    <% other ruby code %>

      becomes

    <code erb-silent> other ruby code </code>

ERB that is contained inside a HTML tag definition is converted slightly differently to ensure a valid HTML document that Nokogiri can parse:

    <p id="<%= dom_id @product %>" <%= "style='display:block';" %>>
   
      becomes

    <p data-erb-id="&lt;%= dom_id @product %&gt;"  data-erb-0="&lt;%= &quot;style='display:block';&quot; %&gt;">

Deface overrides have full access to all variables accessible to the view being customized.

Caveats
======
Deface uses the amazing Nokogiri library (and in turn libxml) for parsing HTML / view files, in some circumstances either Deface's own pre-parser or libxml's will fail to correctly parse a template. You can avoid such issues by ensuring your templates contain valid HTML. Some other caveats include:

1. Ensure that your layout views include doctype, html, head and body tags in a single file, as Nokogiri will create such elements if it detects any of these tags have been incorrectly nested.

2. Parsing will fail and result in invalid output if ERB blocks are responsible for closing an HTML tag that was opened normally, i.e. don't do this:


      <div <%= ">" %>

