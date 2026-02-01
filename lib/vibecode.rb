# frozen_string_literal: true

require_relative "vibecode/version"
require_relative "vibecode/cli"
require_relative "vibecode/ollama_client"
require_relative "vibecode/workspace"
require_relative "vibecode/git"
require_relative "vibecode/agent"

module Vibecode
  class Error < StandardError; end
  # Your code goes here...
end
