require_relative 'lib/deface/version'

Gem::Specification.new do |spec|
  spec.name = "deface"
  spec.version = Deface::VERSION
  spec.authors = ["Brian D Quinn"]
  spec.email = "brian@spreecommerce.com"

  spec.summary = "Deface is a library that allows you to customize ERB, Haml and Slim views in Rails"
  spec.description = "Deface is a library that allows you to customize ERB, Haml and Slim views in a Rails application without editing the underlying view."
  spec.homepage = "https://github.com/spree/deface#readme"
  spec.license = "MIT"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/spree/deface'
  spec.metadata['changelog_uri'] = 'https://github.com/spree/deface/releases'

  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  files = Dir.chdir(__dir__) { `git ls-files -z`.split("\x0") }

  spec.files = files.grep_v(%r{^(test|spec|features)/})
  spec.test_files = files.grep(%r{^(test|spec|features)/})
  spec.bindir = "exe"
  spec.executables = files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.rdoc_options = ["--charset=UTF-8"]
  spec.extra_rdoc_files = ["README.markdown"]

  spec.add_dependency('nokogiri', '>= 1.6')

  %w[
    actionview
    railties
  ].each do |rails_gem|
    spec.add_dependency(rails_gem, '>= 5.2')
  end
  spec.add_dependency('rainbow', '>= 2.1.0')
  spec.add_dependency('polyglot')

  spec.add_development_dependency('appraisal')
  spec.add_development_dependency('erubis')
  spec.add_development_dependency('gem-release')
  spec.add_development_dependency('rspec', '>= 3.1.0')
  spec.add_development_dependency('haml', '>= 4.0', '< 7')
  spec.add_development_dependency('slim', '~> 4.1')
  spec.add_development_dependency('simplecov', '>= 0.6.4')
  spec.add_development_dependency('generator_spec', '~> 0.8')
  spec.add_development_dependency('pry')
end
