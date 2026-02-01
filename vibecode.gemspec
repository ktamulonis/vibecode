# frozen_string_literal: true

require_relative "lib/vibecode/version"

Gem::Specification.new do |spec|
  spec.name = "vibecode"
  spec.version = Vibecode::VERSION
  spec.authors = ["hackliteracy"]
  spec.email = ["hackliteracy@gmail.com"]

  spec.summary = "A local-first “Codex-style” CLI but powered by Ollama"
  spec.description = "Local AI coding agent with abilities like: File editing with diffs, Git command approvals, Model switching, Repo awareness. All on your machine available offline"
  spec.homepage = "https://github.com/ktamulonis/vibecode"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org/"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ktamulonis/vibecode"
  spec.metadata["changelog_uri"] = "https://github.com/ktamulonis/vibecode/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.executables = ["vibecode"]

  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "tty-prompt"
  spec.add_dependency "tty-spinner"
  spec.add_dependency "pastel"
  spec.add_dependency "open3"
  spec.add_dependency "json"
  spec.add_dependency "httparty"
  spec.add_dependency "diffy"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
