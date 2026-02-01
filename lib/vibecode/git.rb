require "open3"
require "tty-prompt"
require "pastel"

module Vibecode
  class Git
    SAFE_COMMANDS = %w[
      status
      diff
      log
      branch
      remote
      fetch
      pull
    ].freeze

    DANGEROUS_COMMANDS = %w[
      add
      commit
      push
      checkout
      merge
      rebase
      reset
      rm
      stash
      tag
    ].freeze

    def initialize(root_dir = Dir.pwd)
      @root_dir = root_dir
      @prompt = TTY::Prompt.new
      @pastel = Pastel.new
    end

    # -----------------------------
    # Public Interface
    # -----------------------------

    def run(command)
      return not_git_repo unless git_repo?

      cmd_parts = command.strip.split
      git_subcommand = cmd_parts[1] # "git status" -> "status"

      unless cmd_parts.first == "git"
        return error("Only git commands are allowed.")
      end

      if SAFE_COMMANDS.include?(git_subcommand)
        execute(command)
      elsif DANGEROUS_COMMANDS.include?(git_subcommand)
        confirm_and_execute(command)
      else
        confirm_and_execute(command) # Unknown = treat as dangerous
      end
    end

    def status
      execute("git status")
    end

    def diff
      execute("git diff")
    end

    def current_branch
      stdout, _stderr, _status = execute("git branch --show-current", capture: true)
      stdout.strip
    end

    def branches
      execute("git branch")
    end

    def log(limit = 10)
      execute("git log --oneline -n #{limit}")
    end

    def add_all
      confirm_and_execute("git add .")
    end

    def commit(message)
      confirm_and_execute(%(git commit -m "#{message}"))
    end

    def push(remote = "origin", branch = current_branch)
      confirm_and_execute("git push #{remote} #{branch}")
    end

    # -----------------------------
    # Core Execution
    # -----------------------------

    private

    def execute(command, capture: false)
      stdout, stderr, status = Open3.capture3(command, chdir: @root_dir)

      unless status.success?
        puts @pastel.red(stderr.strip)
        return [stdout, stderr, status] if capture
        return
      end

      puts @pastel.cyan(stdout.strip) unless capture
      [stdout, stderr, status]
    end

    def confirm_and_execute(command)
      puts @pastel.yellow("\nAI wants to run:\n  #{command}\n")

      approved = @prompt.yes?("Allow this git command?")
      unless approved
        puts @pastel.red("Command cancelled.")
        return
      end

      execute(command)
    end

    # -----------------------------
    # Safety / Checks
    # -----------------------------

    def git_repo?
      system("git rev-parse --is-inside-work-tree > /dev/null 2>&1", chdir: @root_dir)
    end

    def not_git_repo
      error("Not inside a git repository.")
    end

    def error(message)
      puts @pastel.red(message)
      nil
    end
  end
end

