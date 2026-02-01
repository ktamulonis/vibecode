require_relative "workspace"
require_relative "git"

module Vibecode
  class Agent
    def initialize(model:, ollama_client:, root: Dir.pwd)
      @model = model
      @ollama = ollama_client
      @workspace = Workspace.new(root)
      @git = Git.new(root)
      @conversation = []
    end

    # -----------------------------------------
    # Public Entry Point
    # -----------------------------------------
    def handle_user_input(input)
      @conversation << { role: "user", content: input }

      loop do
        response = ask_model
        break unless response

        parsed = parse_response(response)

        show_plan(parsed[:plan]) if parsed[:plan]

        perform_file_reads(parsed[:files_to_read]) if parsed[:files_to_read]
        perform_file_writes(parsed[:files_to_write]) if parsed[:files_to_write]
        perform_commands(parsed[:commands]) if parsed[:commands]

        if parsed[:response]
          puts "\n#{parsed[:response]}"
          @conversation << { role: "assistant", content: parsed[:response] }
        end

        # Stop loop if model did not request more info
        break unless parsed[:files_to_read]
      end
    end

    # -----------------------------------------
    # Model Interaction
    # -----------------------------------------
    def ask_model
      system_prompt = agent_system_prompt
      user_context = build_context_prompt

      raw = @ollama.chat(@model, system_prompt, user_context)
      return nil unless raw && !raw.strip.empty?

      raw
    end

    def build_context_prompt
      convo_text = @conversation.map { |m| "#{m[:role].upcase}: #{m[:content]}" }.join("\n")
      repo_tree = @workspace.tree

      <<~PROMPT
        Conversation so far:
        #{convo_text}

        Project file tree:
        #{repo_tree}

        Respond using the required structured format.
      PROMPT
    end

    # -----------------------------------------
    # Response Parsing
    # -----------------------------------------
    def parse_response(text)
      sections = {
        plan: extract_section(text, "PLAN"),
        files_to_read: extract_list(text, "FILES_TO_READ"),
        files_to_write: extract_file_blocks(text),
        commands: extract_list(text, "COMMANDS"),
        response: extract_section(text, "RESPONSE")
      }
      sections
    end

    def extract_section(text, name)
      text[/#{name}:\s*(.*?)\n(?=[A-Z_]+:|\z)/m, 1]&.strip
    end

    def extract_list(text, name)
      section = extract_section(text, name)
      return nil unless section

      section.lines.map(&:strip).reject(&:empty?)
    end

    def extract_file_blocks(text)
      blocks = text.scan(/FILE:\s*(.*?)\n```.*?\n(.*?)```/m)
      return nil if blocks.empty?

      blocks.map do |path, content|
        { path: path.strip, content: content.rstrip }
      end
    end

    # -----------------------------------------
    # Actions
    # -----------------------------------------
    def show_plan(plan)
      puts "\n🧠 Plan:\n#{plan}\n\n"
    end

    def perform_file_reads(files)
      files.each do |path|
        puts "\n📖 Reading #{path}...\n\n"
        content = @workspace.read_file(path)
        next unless content

        @conversation << {
          role: "user",
          content: "FILE CONTENT (#{path}):\n#{content}"
        }
      end
    end

    def perform_file_writes(files)
      files.each do |file|
        puts "\n✏️  Proposed edit for #{file[:path]}"
        @workspace.write_file(file[:path], file[:content])
      end
    end

    def perform_commands(commands)
      commands.each do |cmd|
        puts "\n⚙️  Running command: #{cmd}"
        @git.run(cmd)
      end
    end

    # -----------------------------------------
    # System Prompt
    # -----------------------------------------
    def agent_system_prompt
      <<~PROMPT
        You are Vibecode, an autonomous terminal coding agent.

        You can:
        - Read project files
        - Modify files
        - Run git commands

        ALWAYS respond in this format:

        PLAN:
        Brief reasoning about what you will do

        FILES_TO_READ:
        path/to/file.rb
        another/file.js

        FILE:
        path/to/file.rb
        ```
        full updated file contents
        ```

        COMMANDS:
        git status
        git add .

        RESPONSE:
        What you want to tell the user

        Rules:
        - Only reference files that exist
        - Do not invent paths
        - Keep edits minimal and complete
        - Prefer reading files before editing
      PROMPT
    end
  end
end

