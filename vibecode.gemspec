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
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org/"

  spec.metadata["source_code_uri"] = "https://github.com/ktamulonis/vibecode"
  spec.metadata["changelog_uri"] = "https://github.com/ktamulonis/vibecode/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) { `git ls-files -z`.split("\x0") }
  spec.bindir = "exe"
  spec.executables = ["vibecode"]

  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "tty-spinner", "~> 0.9"
  spec.add_dependency "pastel", "~> 0.8"
  spec.add_dependency "httparty", "~> 0.21"
  spec.add_dependency "diffy", "~> 3.4"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
