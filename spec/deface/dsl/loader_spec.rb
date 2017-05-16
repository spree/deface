require 'spec_helper'

require 'deface/dsl/loader'

describe Deface::DSL::Loader do
  context '.load' do
    before { allow(File).to receive(:open) }

    context 'extension check' do
      it 'should succeed if file ends with .deface' do
        file = double('deface file')
        filename = 'app/overrides/my_view/example_name.deface'

        expect { Deface::DSL::Loader.load(filename) }.not_to raise_error
      end

      it 'should succeed if file ends with .html.erb.deface' do
        file = double('deface file')
        filename = 'app/overrides/my_view/example_name.html.erb.deface'

        expect { Deface::DSL::Loader.load(filename) }.not_to raise_error
      end

      it 'should succeed if file ends with .html.haml.deface' do
        file = double('deface file')
        filename = 'app/overrides/my_view/example_name.html.haml.deface'

        expect { Deface::DSL::Loader.load(filename) }.not_to raise_error
      end

      it 'should succeed if file ends with .html.slim.deface' do
        file = double('deface file')
        filename = 'app/overrides/my_view/example_name.html.slim.deface'

        expect { Deface::DSL::Loader.load(filename) }.not_to raise_error
      end

      it 'should fail if file ends with .blargh.deface' do
        file = double('deface file')
        filename = 'app/overrides/example_name.blargh.deface'

        expect { Deface::DSL::Loader.load(filename) }.to raise_error(
          "Deface::DSL does not know how to read 'app/overrides/example_name.blargh.deface'. Override files should end with just .deface, .html.erb.deface, .html.haml.deface or .html.slim.deface")
      end

      it "should suceed if parent directory has a dot(.) in it's name" do
        file = double('deface file')
        filename = 'app/overrides/parent.dir.with.dot/example_name.html.haml.deface'

        expect { Deface::DSL::Loader.load(filename) }.not_to raise_error
      end
    end

    it 'should fail if .html.erb.deface file is in the root of app/overrides' do
      file = double('html/erb/deface file')
      filename = 'app/overrides/example_name.html.erb.deface'

      expect { Deface::DSL::Loader.load(filename) }.to raise_error(
        "Deface::DSL overrides must be in a sub-directory that matches the views virtual path. Move 'app/overrides/example_name.html.erb.deface' into a sub-directory.")
    end

    it 'should set the virtual_path for a .deface file in a directory below overrides' do
      file = double('deface file')
      filename = 'app/overrides/path/to/view/example_name.deface'
      expect(File).to receive(:open).with(filename).and_yield(file)

      override_name = 'example_name'
      context = double('dsl context')
      expect(Deface::DSL::Context).to receive(:new).with(override_name).
        and_return(context)

      file_contents = double('file contents')
      expect(file).to receive(:read).and_return(file_contents)

      expect(context).to receive(:virtual_path).with('path/to/view').ordered
      expect(context).to receive(:instance_eval).with(file_contents).ordered
      expect(context).to receive(:create_override).ordered

      Deface::DSL::Loader.load(filename)
    end

    it 'should set the virtual_path for a .html.erb.deface file in a directory below overrides' do
      file = double('html/erb/deface file')
      filename = 'app/overrides/path/to/view/example_name.html.erb.deface'
      expect(File).to receive(:open).with(filename).and_yield(file)

      override_name = 'example_name'
      context = double('dsl context')
      expect(Deface::DSL::Context).to receive(:new).with(override_name).
        and_return(context)

      file_contents = double('file contents')
      expect(file).to receive(:read).and_return(file_contents)

      expect(Deface::DSL::Loader).to receive(:extract_dsl_commands_from_erb).
        with(file_contents).
        and_return(['dsl commands', 'erb'])

      expect(context).to receive(:virtual_path).with('path/to/view').ordered
      expect(context).to receive(:instance_eval).with('dsl commands').ordered
      expect(context).to receive(:erb).with('erb').ordered
      expect(context).to receive(:create_override).ordered

      Deface::DSL::Loader.load(filename)
    end

    it 'should set the virtual_path for a .html.haml.deface file in a directory below overrides' do
      file = double('html/haml/deface file')
      filename = 'app/overrides/path/to/view/example_name.html.haml.deface'
      expect(File).to receive(:open).with(filename).and_yield(file)

      override_name = 'example_name'
      context = double('dsl context')
      expect(Deface::DSL::Context).to receive(:new).with(override_name).
        and_return(context)

      file_contents = double('file contents')
      expect(file).to receive(:read).and_return(file_contents)

      expect(Deface::DSL::Loader).to receive(:extract_dsl_commands_from_haml).
        with(file_contents).
        and_return(['dsl commands', 'haml'])

      expect(context).to receive(:virtual_path).with('path/to/view').ordered
      expect(context).to receive(:instance_eval).with('dsl commands').ordered
      expect(context).to receive(:haml).with('haml').ordered
      expect(context).to receive(:create_override).ordered

      Deface::DSL::Loader.load(filename)
    end

    it 'should set the virtual_path for a .html.slim.deface file in a directory below overrides' do
      file = double('html/slim/deface file')
      filename = 'app/overrides/path/to/view/example_name.html.slim.deface'
      expect(File).to receive(:open).with(filename).and_yield(file)

      override_name = 'example_name'
      context = double('dsl context')
      expect(Deface::DSL::Context).to receive(:new).with(override_name).
        and_return(context)

      file_contents = double('file contents')
      expect(file).to receive(:read).and_return(file_contents)

      expect(Deface::DSL::Loader).to receive(:extract_dsl_commands_from_slim).
        with(file_contents).
        and_return(['dsl commands', 'slim'])

      expect(context).to receive(:virtual_path).with('path/to/view').ordered
      expect(context).to receive(:instance_eval).with('dsl commands').ordered
      expect(context).to receive(:slim).with('slim').ordered
      expect(context).to receive(:create_override).ordered

      Deface::DSL::Loader.load(filename)
    end

    it "should prepend the name of the override with the name of the railtie when loaded from an engine" do
      File.stub(:open).and_yield(mock.as_null_object)

      Deface::Override.current_railtie = 'SpreeEngine'
      Deface::DSL::Context.should_receive(:new).with('spree_engine_assets').and_return(mock.as_null_object)
      Deface::DSL::Loader.load('app/overrides/path/to/view/assets.html.erb.deface')
    end

  end

  context '.register' do
    it 'should register the deface extension with the polyglot library' do
      expect(Polyglot).to receive(:register).with('deface', Deface::DSL::Loader)

      Deface::DSL::Loader.register
    end
  end

  context '.extract_dsl_commands_from_erb' do
    it 'should work in the simplest case' do
      example = "<!-- test 'command' --><h1>Wow!</h1>"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      expect(dsl_commands).to eq "\ntest 'command'"
      expect(the_rest).to eq "<h1>Wow!</h1>"
    end

    it 'should combine multiple comments' do
      example = "<!-- test 'command' --><!-- another 'command' --><h1>Wow!</h1>"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      expect(dsl_commands).to eq "\ntest 'command'\nanother 'command'"
      expect(the_rest).to eq "<h1>Wow!</h1>"
    end

    it 'should leave internal comments alone' do
      example = "<br/><!-- test 'command' --><!-- another 'command' --><h1>Wow!</h1>"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      expect(dsl_commands).to eq ""
      expect(the_rest).to eq example
    end

    it 'should work with comments on own lines' do
      example = "<!-- test 'command' -->\n<!-- another 'command' -->\n<h1>Wow!</h1>"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      expect(dsl_commands).to eq "\ntest 'command'\nanother 'command'"
      expect(the_rest).to eq "\n<h1>Wow!</h1>"
    end

    it 'should work with newlines inside the comment' do
      example = "<!--\n test 'command'\nanother 'command'\n -->\n<h1>Wow!</h1>"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      expect(dsl_commands).to eq "\ntest 'command'\nanother 'command'"
      expect(the_rest).to eq "\n<h1>Wow!</h1>"
    end

    it 'should work with multiple commands on one line' do
      example = %q{<!-- replace_contents 'h1 .title' closing_selector "div#intro" disabled namespaced --><h1>Wow!</h1>}
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      expect(dsl_commands).to eq "\nreplace_contents 'h1 .title'\nclosing_selector \"div#intro\"\ndisabled\nnamespaced"
      expect(the_rest).to eq "<h1>Wow!</h1>"
    end

    it 'should work with multiple commands on one line when command argument is not a normal string' do
      example = %q{<!-- replace_contents 'h1 .title' closing_selector %q{div#intro} disabled namespaced --><h1>Wow!</h1>}
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      expect(dsl_commands).to eq "\nreplace_contents 'h1 .title'\nclosing_selector %q{div#intro}\ndisabled\nnamespaced"
      expect(the_rest).to eq "<h1>Wow!</h1>"
    end

    it 'should work with multiple commands on one line when command argument is an integer' do
      example = %q{<!-- replace_contents 'h1 .title' disabled sequence 2 namespaced --><h1>Wow!</h1>}
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      expect(dsl_commands).to eq "\nreplace_contents 'h1 .title'\ndisabled\nsequence 2\nnamespaced"
      expect(the_rest).to eq "<h1>Wow!</h1>"
    end

    it 'should work with multiple commands on one line when command argument is a hash' do
      example = %q{<!-- add_to_attributes 'h1 .title' attributes :class => 'pretty'--><h1>Wow!</h1>}
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      expect(dsl_commands).to eq "\nadd_to_attributes 'h1 .title'\nattributes :class => 'pretty'"
      expect(the_rest).to eq "<h1>Wow!</h1>"
    end
  end

  context '.extract_dsl_commands_from_haml' do
    it 'should work in the simplest case' do
      example = "/ test 'command'\n/ another 'command'\n%h1 Wow!"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_haml(example)
      expect(dsl_commands).to eq "test 'command'\nanother 'command'\n"
      expect(the_rest).to eq "%h1 Wow!"
    end

    it 'should work with a block style comment using spaces' do
      example = "/\n  test 'command'\n  another 'command'\n%h1 Wow!"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_haml(example)
      expect(dsl_commands).to eq "\ntest 'command'\nanother 'command'\n"
      expect(the_rest).to eq "%h1 Wow!"
    end

    it 'should leave internal comments alone' do
      example = "%br\n/ test 'command'\n/ another 'command'\n%h1 Wow!"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      expect(dsl_commands).to eq ""
      expect(the_rest).to eq example
    end
  end

  context '.extract_dsl_commands_from_slim' do
    it 'should work in the simplest case' do
      example = "/ test 'command'\n/ another 'command'\nh1 Wow!"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_slim(example)
      expect(dsl_commands).to eq "test 'command'\nanother 'command'\n"
      expect(the_rest).to eq "h1 Wow!"
    end

    it 'should work with a block style comment using spaces' do
      example = "/\n  test 'command'\n  another 'command'\nh1 Wow!"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_slim(example)
      expect(dsl_commands).to eq "\ntest 'command'\nanother 'command'\n"
      expect(the_rest).to eq "h1 Wow!"
    end

    it 'should leave internal comments alone' do
      example = "br\n/ test 'command'\n/ another 'command'\nh1 Wow!"
      dsl_commands, the_rest = Deface::DSL::Loader.extract_dsl_commands_from_erb(example)
      expect(dsl_commands).to eq ""
      expect(the_rest).to eq example
    end
  end
end
