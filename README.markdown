<p style="float:right;">
  <a href="http://travis-ci.org/#!/railsdog/deface">
    <img src="http://travis-ci.org/railsdog/deface.png">
  </a>
</p>

Deface
======

Deface is a library that allows you to customize HTML ERB views in a Rails application without editing the underlying view.

It allows you to easily target html & erb elements as the hooks for customization using CSS selectors as supported by Nokogiri.

Demo & Testing
--------------
You can play with Deface and see its parsing in action at [deface.heroku.com](http://deface.heroku.com)


Production & Precompiling
------------------------

Deface now supports precompiling where all overrides are loaded and applied to the original views and the resulting templates are then saved to your application's `app/compiled_views` directory. To precompile run:

     bundle exec rake deface:precompile

It's important to disable Deface once precompiling is used to prevent overrides getting applied twice. To disable add the following line to your application's `production.rb` file:

     config.deface.enabled = false

NOTE: You can also use precompiling in development mode.


Deface::Override
================

A new instance of the Deface::Override class is initialized for each customization you wish to define. When initializing a new override you must supply only one Target, Action & Source parameter and any number of Optional parameters. Note: the source parameter is not required when the "remove" action is specified.

Target
------
* <tt>:virtual_path</tt> - The template / partial / layout where the override should take effect eg: *"shared/_person"*, *"admin/posts/new"* this will apply to all controller actions that use the specified template.

Action
------
* <tt>:remove</tt> - Removes all elements that match the supplied selector

* <tt>:replace</tt> - Replaces all elements that match the supplied selector

* <tt>:replace_contents</tt> - Replaces the contents of all elements that match the supplied selector

* <tt>:surround</tt> - Surrounds all elements that match the supplied selector, expects replacement markup to contain <%= render_original %> placeholder

* <tt>:surround_contents</tt> - Surrounds the contents of all elements that match the supplied selector, expects replacement markup to contain <%= render_original %> placeholder

* <tt>:insert_after</tt> - Inserts after all elements that match the supplied selector

* <tt>:insert_before</tt> - Inserts before all elements that match the supplied selector

* <tt>:insert_top</tt> - Inserts inside all elements that match the supplied selector, as the first child.

* <tt>:insert_bottom</tt> - Inserts inside all elements that match the supplied selector, as the last child.

* <tt>:set_attributes</tt> - Sets (or adds) attributes to all elements that match the supplied selector, expects :attributes option to be passed.

Source
------
* <tt>:text</tt> - String containing markup

* <tt>:partial</tt> - Relative path to a partial

* <tt>:template</tt> - Relative path to a template


Optional
--------
* <tt>:name</tt> - Unique name for override so it can be identified and modified later. This needs to be unique within the same `:virtual_path`

* <tt>:disabled</tt> - When set to true the override will not be applied.

* <tt>:original</tt> - String containing original markup that is being overridden. If supplied Deface will log when the original markup changes, which helps highlight overrides that need attention when upgrading versions of the source application. Only really warranted for :replace overrides. NB: All whitespace is stripped before comparison.

* <tt>:closing_selector</tt> - A second css selector targeting an end element, allowing you to select a range of elements to apply an action against. The :closing_selector only supports the :replace, :remove and :replace_contents actions, and the end element must be a sibling of the first/starting element. Note the CSS general sibling selector (~) is used to match the first element after the opening selector (see below for an example).

* <tt>:sequence</tt> - Used to order the application of an override for a specific virtual path, helpful when an override depends on another override being applied first, supports:
  * <tt>:sequence => n</tt> - where n is a positive or negative integer (lower numbers get applied first, default 100).
  * <tt>:sequence => {:before => "*override_name*"}</tt> - where "*override_name*" is the name of an override defined for the 
                                              same virutal_path, the current override will be appplied before 
                                              the named override passed.
  * <tt>:sequence => {:after => "*override_name*")</tt> - the current override will be applied after the named override passed.

* <tt>:attributes</tt> - A hash containing all the attributes to be set on the matched elements, eg: :attributes => {:class => "green", :title => "some string"}

Examples
========

Replaces all instances of `h1` in the `posts/_form.html.erb` partial with `<h1>New Post</h1>`

     Deface::Override.new(:virtual_path => "posts/_form", 
                          :name => "example-1", 
                          :replace => "h1", 
                          :text => "<h1>New Post</h1>")

Alternatively pass it a block of code to run:

     Deface::Override.new(:virtual_path => "posts/_form",
                          :name => "example-1",
                          :replace => "h1") do
       "<h1>New Post</h1>"
     end

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

Removes any ERB block containing the string `helper_method` in the `posts/new.html.erb` template, will also log if markup being removed does not exactly match `<%= helper_method %>`

     Deface::Override.new(:virtual_path => "posts/new", 
                          :name => "example-4", 
                          :remove => "code[erb-loud]:contains('helper_method')",
                          :original => "<%= helper_method %>")

Wraps the `div` with id of `products` in ruby if statement, the <%= render_original %> in the `text` indicates where the matching content should be re-included.

     Deface::Override.new(:virtual_path => "posts/new", 
                          :name => "example-5", 
                          :surround => "div#products",
                          :text => "<% if @product.present? %><%= render_original %><% end %>")

Sets (or adds if not present) the `class` and `title` attributes to all instances of `a` with an id of `link` in `posts/index.html.erb` 

    Deface::Override.new(:virtual_path => 'posts/index',
                        :name => 'add_attrs_to_a_link',
                        :set_attributes => 'a#link',
                        :attributes => {:class => 'pretty', :title => 'This is a link'})

Remove an entire ERB if statement (and all it's contents) in the 'admin/products/index.html.erb' template, using the :closing_selector.

    Deface::Override.new(:virtual_path => 'admin/products/index',
                         :name => "remove_if_statement",
                         :remove => "code[erb-silent]:contains('if @product.sold?')",
                         :closing_selector => "code[erb-silent]:contains('end')"

Scope
=====

Deface scopes overrides by virtual_path (or partial / template file), that means all override names only need to be unique within that single file.

Redefining Overrides
====================

You can redefine an existing override by simply declaring a new override with the same <tt>:virtual_path</tt> and <tt>:name</tt> that was originally used.
You do not need to resupply all the values originally used, just the ones you want to change:

   Deface::Override.new(:virtual_path => 'posts/index',
                        :name => 'add_attrs_to_a_link',
                        :disabled => true)

Rake Tasks
==========

Deface includes a couple of rake tasks that can be helpful when defining or debugging overrides.

**deface:get_result** - Will list the original contents of a partial or template, the overrides that have been defined for a that file, and the resulting markup. *get_result* takes a single argument which is the virtual path of the template / partial:

    rake deface:get_result[shared/_head]

    rake deface:get_result['admin/products/index']

**deface:test_selector** - Applies a given CSS selector against a partial or template and outputs the markup for each match (if any). *test_selector* requires two arguments, the first is the virtual_path for the partial / template, the second is the CSS selector to apply:

    rake deface:test_selector[shared/_head,title]

    rake deface:test_selector['admin/products/index','div.toolbar']

**deface:precompile** - Generates compiled views that contain all overrides applied. See `Production & Precompiling` section above for more.

    rake deface:precompile


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

      &lt;div <%= ">" %>
