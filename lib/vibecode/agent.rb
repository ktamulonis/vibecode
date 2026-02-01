require_relative "workspace"
require_relative "git"
require "tty-prompt"
require "pastel"

module Vibecode
  class Agent
    def initialize(model:, ollama_client:, root: Dir.pwd)
      @model = model
      @ollama = ollama_client
      @workspace = Workspace.new(root)
      @git = Git.new(root)
      @conversation = []
      @prompt = TTY::Prompt.new
      @pastel = Pastel.new
    end

    # -----------------------------------------
    # Public Entry Point
    # -----------------------------------------
    def handle_user_input(input)
      @conversation << { role: "user", content: input }

      response = ask_model
      return unless response

      parsed = parse_response(response)
      missing_read_suggestions = {}
      if parsed[:files_to_read]
        missing_read_suggestions = perform_file_reads(parsed[:files_to_read], input)
        response = ask_model
        return unless response

        parsed = parse_response(response)
      end

      files_to_write = normalize_files_to_write(parsed[:files_to_write], input, missing_read_suggestions)
      actions = plan_actions(files_to_write, input)

      show_plan(parsed[:plan]) if parsed[:plan]
      preview_diffs(files_to_write) if files_to_write && !files_to_write.empty?

      if actions && !actions.empty?
        puts "\nVibecode plans to:\n- #{actions.join("\n- ")}\n"
        approved = @prompt.yes?("Proceed?")
        unless approved
          puts @pastel.red("Plan cancelled.")
          return
        end
      end

      written_files = perform_file_writes(files_to_write)
      run_results = run_ruby_files(written_files, files_to_write)

      if parsed[:commands] && user_asked_for_git?(input)
        perform_commands(parsed[:commands])
      end

      if run_results.any?
        @conversation << { role: "user", content: format_execution_results(run_results) }
        report = ask_model(stage: :report)
        if report
          report_parsed = parse_response(report)
          print_response(report_parsed[:response]) if report_parsed[:response]
          return
        end
      end

      print_response(parsed[:response]) if parsed[:response]
    end

    # -----------------------------------------
    # Model Interaction
    # -----------------------------------------
    def ask_model(stage: :normal)
      system_prompt = agent_system_prompt(stage: stage)
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

    def perform_file_reads(files, task_description)
      missing = {}
      used = {}

      files.each do |path|
        if @workspace.file_exists?(path)
          puts "\n📖 Reading #{path}...\n\n"
          content = @workspace.read_file(path)
          next unless content

          @conversation << {
            role: "user",
            content: "FILE CONTENT (#{path}):\n#{content}"
          }
        else
          suggested = resolve_new_file_path(task_description, used)
          missing[path] = suggested
          @conversation << {
            role: "user",
            content: "REQUESTED FILE NOT FOUND (#{path}). Create new file: #{suggested}."
          }
        end
      end

      missing
    end

    def preview_diffs(files)
      files.each do |file|
        puts "\n✏️  Proposed edit for #{file[:path]}"
        diff = @workspace.diff_for(file[:path], file[:content])
        puts diff.empty? ? @pastel.dim("(No changes)") : diff
      end
    end

    def perform_file_writes(files)
      return [] unless files

      written = []
      files.each do |file|
        puts "\n✏️  Writing #{file[:path]}"
        success = @workspace.write_file(file[:path], file[:content], show_diff: false)
        written << file[:path] if success
      end
      written
    end

    def perform_commands(commands)
      commands.each do |cmd|
        puts "\n⚙️  Running command: #{cmd}"
        @git.run(cmd)
      end
    end

    def run_ruby_files(written_paths, files_to_write)
      return [] if written_paths.nil? || written_paths.empty?

      by_path = (files_to_write || []).each_with_object({}) do |file, acc|
        acc[file[:path]] = file[:content]
      end

      results = []
      written_paths.each do |path|
        next unless path.end_with?(".rb")

        content = by_path[path]
        unless @workspace.ruby_executable_content?(content.to_s)
          next
        end

        puts "\n▶️  Running: ruby #{path}"
        result = @workspace.run_ruby(path)
        next if result[:skipped]

        results << result.merge(path: path)
        print_run_result(result)
      end
      results
    end

    def print_run_result(result)
      stdout = result[:stdout].to_s
      stderr = result[:stderr].to_s

      puts stdout unless stdout.empty?
      puts @pastel.red(stderr) unless stderr.empty?
    end

    def format_execution_results(results)
      lines = ["RUBY EXECUTION RESULTS:"]
      results.each do |res|
        status = res[:status]&.success? ? "success" : "failure"
        lines << "COMMAND: #{res[:command]}"
        lines << "STATUS: #{status}"
        lines << "STDOUT:\n#{res[:stdout].to_s.strip}"
        lines << "STDERR:\n#{res[:stderr].to_s.strip}"
      end
      lines.join("\n")
    end

    def normalize_files_to_write(files, task_description, missing_read_suggestions)
      return [] unless files

      used = {}
      files.map do |file|
        if @workspace.file_exists?(file[:path])
          { path: file[:path], content: file[:content] }
        else
          suggested = missing_read_suggestions[file[:path]] || resolve_new_file_path(task_description, used)
          { path: suggested, content: file[:content] }
        end
      end
    end

    def resolve_new_file_path(task_description, used)
      base = @workspace.suggest_filename(task_description)
      candidate = base
      index = 2

      while @workspace.file_exists?(candidate) || used[candidate]
        stem = base.sub(/\.rb\z/, "")
        candidate = "#{stem}_#{index}.rb"
        index += 1
      end

      used[candidate] = true
      candidate
    end

    def user_asked_for_git?(input)
      input.to_s.downcase.match?(/\bgit\b/)
    end

    def plan_actions(files_to_write, user_input)
      actions = []

      (files_to_write || []).each do |file|
        if @workspace.file_exists?(file[:path])
          actions << "update file #{file[:path]}"
        else
          actions << "create file #{file[:path]}"
        end

        if file[:path].end_with?(".rb") && @workspace.ruby_executable_content?(file[:content].to_s)
          actions << "run ruby #{file[:path]}"
        end
      end

      if user_asked_for_git?(user_input)
        actions << "run git commands" if actions.empty?
      end

      actions
    end

    def approve_actions!(actions)
      return if actions.nil? || actions.empty?

      puts "\nVibecode plans to:\n- #{actions.join("\n- ")}\n\nProceed?"
      approved = @prompt.yes?(" ")
      unless approved
        puts @pastel.red("Plan cancelled.")
        return
      end
    end

    def print_response(response)
      puts "\n#{response}"
      @conversation << { role: "assistant", content: response }
    end

    # -----------------------------------------
    # System Prompt
    # -----------------------------------------
    def agent_system_prompt(stage: :normal)
      base = <<~PROMPT
        You are Vibecode, an autonomous terminal coding agent.

        You can:
        - Read project files
        - Modify files

        ALWAYS respond in this format:

        PLAN:
        Brief reasoning about what you will do

        FILES_TO_READ:
        existing/file.rb
        another/existing/file.js

        FILE:
        filename.rb
        ```
        full updated file contents
        ```

        COMMANDS:
        git status
        git diff

        RESPONSE:
        What you want to tell the user

        Rules:
        - Only list existing files in FILES_TO_READ
        - If you need to create a new file, propose a reasonable filename like hello_world.rb (never placeholders like path/to/file.rb)
        - Do not include COMMANDS unless the user explicitly asked for git
        - Keep edits minimal and complete
        - Prefer reading files before editing
      PROMPT

      return base if stage == :normal

      <<~PROMPT
        #{base}

        REPORT BACK STAGE:
        - Only provide the RESPONSE section
        - Do not request file reads or file writes
        - Do not include COMMANDS
      PROMPT
    end
  end
end
