# Deface

[![Travis build](https://secure.travis-ci.org/spree/deface.svg?branch=master)](https://travis-ci.com/github/spree/deface)

Deface is a library that allows you to customize HTML (ERB, Haml and Slim) views in a Rails application without editing the underlying view.

It allows you to easily target html & erb elements as the hooks for customization using CSS selectors as supported by Nokogiri.


## Usage

There are two ways of using Deface:

- Using `Deface::Override` - this is the traditional method whereby you define instances of the Deface::Override class directly.
- Using the Deface DSL (.deface files) - the DSL provides a terser syntax, and better organization of the individual override files.

Both methods are interoperable, so you can use a mix, and redefine overrides defined one-way using the other.



## Using Deface::Override

A new instance of the Deface::Override class is initialized for each customization you wish to define. When initializing a new override you must supply only one Target, Action & Source parameter and any number of Optional parameters.

**Note:** the source parameter is not required when the ````:remove, :set_attributes, :add_to_attributes, :remove_from_attributes```` actions are specified.

You should save your overrides in the ````app/overrides````, normally one override per file using the same file name as specified in the :name argument. Deface will automatically require these from your application, and any engines installed.

**Note:** You should NOT manually require override files, as this can cause problems for precompiling.

### Target

* `:virtual_path` - The template / partial / layout where the override should take effect eg: *"shared/_person"*, *"admin/posts/new"* this will apply to all controller actions that use the specified template.

### Action

* `:remove` - Removes all elements that match the supplied selector

* `:replace` - Replaces all elements that match the supplied selector

* `:replace_contents` - Replaces the contents of all elements that match the supplied selector

* `:surround` - Surrounds all elements that match the supplied selector, expects replacement markup to contain <%= render_original %> placeholder

* `:surround_contents` - Surrounds the contents of all elements that match the supplied selector, expects replacement markup to contain <%= render_original %> placeholder

* `:insert_after` - Inserts after all elements that match the supplied selector

* `:insert_before` - Inserts before all elements that match the supplied selector

* `:insert_top` - Inserts inside all elements that match the supplied selector, as the first child.

* `:insert_bottom` - Inserts inside all elements that match the supplied selector, as the last child.

* `:set_attributes` - Sets attributes on all elements that match the supplied selector, replacing existing attribute value if present or adding if not. Expects :attributes option to be passed.

* `:add_to_attributes` - Appends value to attributes on all elements that match the supplied selector, adds attribute if not present. Expects :attributes option to be passed.

* `:remove_from_attributes` - Removes value from attributes on all elements that match the supplied selector. Expects :attributes option to be passed.

### Source

* `:text` - String containing markup

* `:partial` - Relative path to a partial

* `:template` - Relative path to a template

* `:cut` - Cuts (i.e. copies and removes) an element or a range of elements from the current template as the source, using css selector(s). Supports two versions:
  * `selector` -  A single string css selector (first match is used).
  * `{:start => 'selector_a', :end => 'selector_b'}` - select a range of elements using :start and :end css selectors. The end element must be a sibling of the first/starting element.

* `:copy` - Copies an element or a range of elements from the current template as the source, using css selector(s). Supports two versions:
  * `selector` -  A single string css selector (first match is used).
  * `{:start => 'selector_a', :end => 'selector_b'}` - select a range of elements using :start and :end css selectors. The end element must be a sibling of the first/starting element.

### Optional

* `:name` - Unique name for override so it can be identified and modified later. This needs to be unique within the same `:virtual_path`

* `:disabled` - When set to true the override will not be applied.

* `:original` - Either a string containing the original markup that is being overridden, or a string that is the SHA1 digest of the original markup. If supplied Deface will log when the original markup changes, which helps highlight overrides that need attention when upgrading versions of the source application. Only really warranted for :replace overrides. NB: All whitespace is stripped before comparison. To generate the SHA1 digest do: `Digest::SHA1.hexdigest(original_markup_string.gsub(/\s/, ''))`

* `:closing_selector` - A second css selector targeting an end element, allowing you to select a range of elements to apply an action against. The :closing_selector only supports the :replace, :remove and :replace_contents actions, and the end element must be a sibling of the first/starting element. Note the CSS general sibling selector (~) is used to match the first element after the opening selector (see below for an example).

* `:sequence` - Used to order the application of an override for a specific virtual path, helpful when an override depends on another override being applied first, supports:
  * `:sequence => n` - where n is a positive or negative integer (lower numbers get applied first, default 100).
  * `:sequence => {:before => "*override_name*"}` - where "*override_name*" is the name of an override defined for the
                                              same virtual_path, the current override will be appplied before
                                              the named override passed.
  * `:sequence => {:after => "*override_name*"}` - the current override will be applied after the named override passed.

* `:attributes` - A hash containing all the attributes to be set on the matched elements, eg: :attributes => {:class => "green", :title => "some string"}

### Examples

Replaces all instances of `h1` in the `posts/_form.html.erb` partial with `<h1>New Post</h1>`

```ruby
Deface::Override.new(:virtual_path => "posts/_form",
                     :name => "example-1",
                     :replace => "h1",
                     :text => "<h1>New Post</h1>")
```

Alternatively pass it a block of code to run:

```ruby
Deface::Override.new(:virtual_path => "posts/_form",
                     :name => "example-1",
                     :replace => "h1") do
  "<h1>New Post</h1>"
end
```

Inserts `<%= link_to "List Comments", comments_url(post) %>` before all instances of `p` with css class `comment` in `posts/index.html.erb`

```ruby
Deface::Override.new(:virtual_path => "posts/index",
                     :name => "example-2",
                     :insert_before => "p.comment",
                     :text => "<%= link_to 'List Comments', comments_url(post) %>")
```

Inserts the contents of `shared/_comment.html.erb` after all instances of `div` with an id of `comment_21` in `posts/show.html.erb`

```ruby
Deface::Override.new(:virtual_path => "posts/show",
                     :name => "example-3",
                     :insert_after => "div#comment_21",
                     :partial => "shared/comment")
```

Removes any ERB block containing the string `helper_method` in the `posts/new.html.erb` template, will also log if markup being removed does not exactly match `<%= helper_method %>`

```ruby
Deface::Override.new(:virtual_path => "posts/new",
                     :name => "example-4",
                     :remove => "erb[loud]:contains('helper_method')",
                     :original => "<%= helper_method %>")
```

Wraps the `div` with id of `products` in ruby if statement, the <%= render_original %> in the `text` indicates where the matching content should be re-included.

```ruby
Deface::Override.new(:virtual_path => "posts/new",
                     :name => "example-5",
                     :surround => "div#products",
                     :text => "<% if @product.present? %><%= render_original %><% end %>")
```

Sets (or adds if not present) the `class` and `title` attributes to all instances of `a` with an id of `link` in `posts/index.html.erb`

```ruby
Deface::Override.new(:virtual_path => 'posts/index',
                     :name => 'add_attrs_to_a_link',
                     :set_attributes => 'a#link',
                     :attributes => {:class => 'pretty', :title => 'This is a link'})
```

Remove an entire ERB if statement (and all it's contents) in the 'admin/products/index.html.erb' template, using the :closing_selector.

```ruby
Deface::Override.new(:virtual_path => 'admin/products/index',
                     :name => "remove_if_statement",
                     :remove => "erb[silent]:contains('if @product.sold?')",
                     :closing_selector => "erb[silent]:contains('end')")
```

### Scope

Deface scopes overrides by virtual_path (or partial / template file), that means all override names only need to be unique within that single file.

### Redefining Overrides

You can redefine an existing override by simply declaring a new override with the same `:virtual_path`, `:name` and [action](#action) that was originally used.
You do not need to resupply all the values originally used, just the ones you want to change:

```ruby
Deface::Override.new(:virtual_path => 'posts/index',
                     :name => 'add_attrs_to_a_link',
                     :set_attributes => 'a#link',
                     :disabled => true)
```

### Namespacing

If you want to avoid inadvertently redefining overrides in other engines, you can use the `namespaced` option to have
an override automatically be namespaced to the engine in which it was defined:

```ruby
Deface::Override.new(:virtual_path => 'posts/index',
                     :name => 'add_link',
                     :namespaced => true)
```

So for example if the above override was defined in `MyEngine` it would be automatically named `my_engine_add_link`.
This can also be activated globally for all DSL overrides in your app's `application.rb` file:

```ruby
config.deface.namespaced = true # default is false
```

## Using the Deface DSL (.deface files)

Instead of defining Deface::Override instances directly, you can alternatively add `.deface` files to the `app/overrides` folder and Deface will automatically pick them up.
The path of each override should match the path of the view template you want to modify, say for example if you have a template at:

    app/views/posts/_post.html.erb

Then you can override it by adding a .deface file at:

    app/overrides/posts/_post/my_override.html.erb.deface

The format of a .deface file is a comment showing the action to be performed, followed by any markup that would be normally passed to the :erb, :text, :haml arguments:

```html
<!-- insert_after 'h1' -->
<h2>These robots are awesome.</h2>
```

The same effect can also be achieved with haml, by changing the overrides filename to:

    app/overrides/posts/_post/my_override.html.haml.deface

and including haml source:

```haml
/
  insert_after 'h1'
%h2 These robots are awesome.
```

#### Additional Options

You can include all the additional options you can normally use when defining a Deface::Override manually, a more complex example:

```html
<!-- replace_contents 'h1' closing_selector 'div#intro'
  sequence :before => 'my_other_override'
  disabled -->
<p>This is a complicated example</p>
```
Note options requiring a hash should be on a separate line.

#### Disabled / Enabled

The DSL does not accept the instance style ````:disabled => boolean```` instead you can simply include either:

```html
<!-- enabled -->
```

or

```html
<!-- disabled -->
```

#### Namespacing

When using the DSL, overrides automatically take their name from the filename of the file in which they are defined
(ie `my_override.html.erb.deface` becomes `my_override`) so overrides with the same filename will replace each other,
even if they are defined in separate engines. If you want to avoid this, you can use the `namespaced` option :

```erb
<!-- insert_bottom 'head' namespaced -->
```

or activate it globally for all DSL overrides in your app's `application.rb` file:

```ruby
config.deface.namespaced = true # default is false
```

Each override will then have its name namespaced to the engine in which it was defined
(ie `my_override.html.erb.deface` defined in `MyEngine` becomes `my_engine_my_override`),
allowing overrides in different engines with identical filenames to co-exist.

### DSL usage for overrides that do not include markup

If your override does not require any markup, for example actions including ````:remove, :set_attributes, :remove_from_attributes, :add_to_attributes```` you can exclude the "html.erb" or "html.haml" from the file name and you do not need to wrap the arguments in a comment.

So the override filename becomes simply:

    app/overrides/posts/_post/my_override.deface

And the contents:

```ruby
add_to_attributes 'a#search'
attributes :alt => 'Click here to search'
```


## Rake Tasks

Deface includes a couple of rake tasks that can be helpful when defining or debugging overrides.

`rake deface:get_result` - Will list the original contents of a partial or template, the overrides that have been defined for a that file, and the resulting markup. *get_result* takes a single argument which is the virtual path of the template / partial:

    rake deface:get_result[shared/_head]

    rake deface:get_result['admin/products/index']

`rake deface:test_selector` - Applies a given CSS selector against a partial or template and outputs the markup for each match (if any). *test_selector* requires two arguments, the first is the virtual_path for the partial / template, the second is the CSS selector to apply:

    rake deface:test_selector[shared/_head,title]

    rake deface:test_selector['admin/products/index','div.toolbar']

`rake deface:precompile` - Generates compiled views that contain all overrides applied. See `Production & Precompiling` section below for more.

    rake deface:precompile

## Production & Precompiling

Deface now supports precompiling where all overrides are loaded and applied to the original views and the resulting templates are then saved to your application's `app/compiled_views` directory. To precompile run:

     DEFACE_ENABLED=true bundle exec rake deface:precompile

It's important to disable Deface once precompiling is used to prevent overrides getting applied twice. To disable add the following line to your application's `production.rb` file:

```ruby
config.deface.enabled = ENV['DEFACE_ENABLED'] == 'true'
```

NOTE: You can also use precompiling in development mode.

### Adding to Capistrano

Adding the following to your `deploy.rb` will automatically compile the views during deploy

```ruby
namespace :deface do
  desc "Pre-compile Deface overrides into templates"
  task :precompile do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env), deface_enabled: true do
          execute :rake, 'deface:precompile'
        end
      end
    end
  end
end

after 'deploy:updated', 'deface:precompile'
```

## Upgrading from 0.9 to 1.0

If you are updating from 0.9.x to 1.0.0 or higher, there's a major internal change you should be aware of.

Previously, erb blocks (i.e. <%= some_method %>) were converted as:

```html
  <code erb-loud> some_method </code>
```
They are now converted to:

```html
  <erb loud> some_method </erb>
```

This change will affect any Override that uses a selector that matches on `code` or `code[erb-loud]` or `code[erb-silent]` etc, they should be updated to `erb`, `erb[loud]` or `erb[silent]`, etc.

Note: HAML & SLIM are preconverted to ERB before Deface parsers them, so the same conversions are happening there.

See the [Implementation](#implementation) section below for more details.


# Implementation

Deface temporarily converts ERB files into a pseudo HTML markup that can be parsed and queried by Nokogiri, using the following approach:

```erb
<%= some ruby code %>
```

becomes:

```html
<erb loud> some ruby code </erb>
```

and

```erb
<% other ruby code %>
```

becomes:

```html
<erb silent> other ruby code </erb>
```

ERB that is contained inside a HTML tag definition is converted slightly differently to ensure a valid HTML document that Nokogiri can parse:

```erb
<p id="<%= dom_id @product %>" <%= "style='display:block';" %>>
```

becomes:

```html
<p data-erb-id="&lt;%= dom_id @product %&gt;"  data-erb-0="&lt;%= &quot;style='display:block';&quot; %&gt;">
```

Deface overrides have full access to all variables accessible to the view being customized.


# Caveats

Deface uses the amazing Nokogiri library (and in turn libxml) for parsing HTML / view files, in some circumstances either Deface's own pre-parser or libxml's will fail to correctly parse a template. You can avoid such issues by ensuring your templates contain valid HTML. Some other caveats include:

1. Ensure that your layout views include doctype, html, head and body tags in a single file, as Nokogiri will create such elements if it detects any of these tags have been incorrectly nested.

2. Parsing will fail and result in invalid output if ERB blocks are responsible for closing an HTML tag that was opened normally, i.e. don't do this: `&lt;div <%= ">" %>`

3. Gems or Spree Extensions that add overrides to your application will load them in the order they are added to your Gemfile.

4. Applying an override to a view that contains invalid markup (which, occasionally happens in Spree views) can break rendering that would normally pass a browser's own permissive rendering.  This is because the nokogiri library takes it upon itself to correct the issue, which doesn't happen prior to applying deface.  Sometimes that correction changes the rendering of the view in an unintended manner, appearing to break it.  The easiest way to tell if this is the cause of an issue for you is to put your view into http://deface.heroku.com/ and diff the output with the html which rails renders without your override.  If you see a difference in the structure of the html, you may have invalid markup in your view which nokogiri is correcting for you.  See [Spree issue #1789](https://github.com/spree/spree/pull/1789) for an example of what may be wrong in a view.
