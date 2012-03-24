require 'spec_helper'

require 'deface/dsl/loader'

describe Deface::DSL::Loader do
  context '.load' do
    it 'should fail if file ends with .deface, but not .html.erb.deface or .html.haml.deface' do
      file = mock('deface file')
      filename = 'app/overrides/example_name.deface'

      lambda { Deface::DSL::Loader.load(filename) }.should raise_error(
        "Deface::DSL does not know how to read 'app/overrides/example_name.deface'. Override files should end with .html.erb.deface or .html.haml.deface")
    end

    it 'should fail if .html.erb.deface file is in the root of app/overrides' do
      file = mock('html/erb/deface file')
      filename = 'app/overrides/example_name.html.erb.deface'

      lambda { Deface::DSL::Loader.load(filename) }.should raise_error(
        "Deface::DSL overrides must be in a sub-directory that matches the views virtual path. Move 'app/overrides/example_name.html.erb.deface' into a sub-directory.")
    end

    it 'should set the virtual_path for a .html.erb.deface file in a directory below overrides' do
      file = mock('html/erb/deface file')
      filename = 'app/overrides/path/to/view/example_name.html.erb.deface'
      File.should_receive(:open).with(filename).and_yield(file)

      override_name = 'example_name'
      context = mock('dsl context')
      Deface::DSL::Context.should_receive(:new).with(override_name).
        and_return(context)

      file_contents = mock('file contents')
      file.should_receive(:read).and_return(file_contents)

      Deface::DSL::Loader.should_receive(:extract_dsl_commands_from_erb).
        with(file_contents).
        and_return(['dsl commands', 'erb'])

      context.should_receive(:instance_eval).with('dsl commands')
      context.should_receive(:erb).with('erb')
      context.should_receive(:virtual_path).with('path/to/view')
      context.should_receive(:create_override)

      Deface::DSL::Loader.load(filename)
    end

    it 'should set the virtual_path for a .html.haml.deface file in a directory below overrides' do
      file = mock('html/haml/deface file')
      filename = 'app/overrides/path/to/view/example_name.html.haml.deface'
      File.should_receive(:open).with(filename).and_yield(file)

      override_name = 'example_name'
      context = mock('dsl context')
      Deface::DSL::Context.should_receive(:new).with(override_name).
        and_return(context)

      file_contents = mock('file contents')
      file.should_receive(:read).and_return(file_contents)

      Deface::DSL::Loader.should_receive(:extract_dsl_commands_from_haml).
        with(file_contents).
        and_return(['dsl commands', 'haml'])

      context.should_receive(:instance_eval).with('dsl commands')
      context.should_receive(:haml).with('haml')
      context.should_receive(:virtual_path).with('path/to/view')
      context.should_receive(:create_override)

      Deface::DSL::Loader.load(filename)
    end

  end

  context '.register' do
    it 'should register the deface extension with the polyglot library' do
      Polyglot.should_receive(:register).with('deface', Deface::DSL::Loader)

      Deface::DSL::Loader.register
    end
  end

  context '.extract_dsl_commands_from_erb' do
    it 'should work in the simplest case' do
      example = "<!-- test 'command' --><h1>Wow!</h1>"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      dsl_commands.should == "test 'command'\n"
      the_rest.should == "<h1>Wow!</h1>"
    end

    it 'should combine multiple comments' do
      example = "<!-- test 'command' --><!-- another 'command' --><h1>Wow!</h1>"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      dsl_commands.should == "test 'command'\nanother 'command'\n"
      the_rest.should == "<h1>Wow!</h1>"
    end

    it 'should leave internal comments alone' do
      example = "<br/><!-- test 'command' --><!-- another 'command' --><h1>Wow!</h1>"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      dsl_commands.should == ""
      the_rest.should == example
    end

    it 'should work with comments on own lines' do
      example = "<!-- test 'command' -->\n<!-- another 'command' -->\n<h1>Wow!</h1>"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      dsl_commands.should == "test 'command'\nanother 'command'\n"
      the_rest.should == "\n<h1>Wow!</h1>"
    end

    it 'should work with newlines inside the comment' do
      example = "<!--\n test 'command'\nanother 'command'\n -->\n<h1>Wow!</h1>"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      dsl_commands.should == "test 'command'\nanother 'command'\n"
      the_rest.should == "\n<h1>Wow!</h1>"
    end
  end

  context '.extract_dsl_commands_from_haml' do
    it 'should work in the simplest case' do
      example = "/ test 'command'\n/ another 'command'\n%h1 Wow!"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_haml(example)
      dsl_commands.should == "test 'command'\nanother 'command'\n"
      the_rest.should == "%h1 Wow!"
    end

    it 'should work with a block style comment using spaces' do
      example = "/\n  test 'command'\n  another 'command'\n%h1 Wow!"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_haml(example)
      dsl_commands.should == "\ntest 'command'\nanother 'command'\n"
      the_rest.should == "%h1 Wow!"
    end

    it 'should leave internal comments alone' do
      example = "%br\n/ test 'command'\n/ another 'command'\n%h1 Wow!"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      dsl_commands.should == ""
      the_rest.should == example
    end

  end
end