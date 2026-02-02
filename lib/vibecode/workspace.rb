require "fileutils"
require "pathname"
require "tty-prompt"
require "pastel"
require "diffy"
require "open3"
require "tty-reader"

module Vibecode
  class Workspace
    attr_reader :root

    def initialize(root = Dir.pwd)
      @root = File.expand_path(root)
      @prompt = TTY::Prompt.new
      @pastel = Pastel.new
    end

    # --------------------------------------------------
    # File Reading
    # --------------------------------------------------

    def read_file(path)
      full_path = safe_path(path)
      return error("File does not exist: #{path}") unless File.exist?(full_path)

      File.read(full_path)
    rescue => e
      error("Failed to read file: #{e.message}")
    end

    def file_exists?(path)
      full_path = safe_path(path)
      File.exist?(full_path)
    rescue
      false
    end

    def list_files(limit: 200)
      files = Dir.glob("**/*", base: @root)
                 .reject { |f| File.directory?(File.join(@root, f)) }
                 .first(limit)

      files.join("\n")
    end

    # --------------------------------------------------
    # File Writing
    # --------------------------------------------------

    def diff_for(path, new_content)
      full_path = safe_path(path)
      old_content = File.exist?(full_path) ? File.read(full_path) : ""
      Diffy::Diff.new(old_content, new_content, context: 3).to_s(:color)
    rescue => e
      error("Failed to diff file: #{e.message}")
      ""
    end

    def write_file(path, new_content, show_diff: true)
      full_path = safe_path(path)

      if show_diff
        diff = diff_for(path, new_content)
        puts @pastel.yellow("\nProposed changes to #{path}:\n")
        puts diff.empty? ? @pastel.dim("(No changes)") : diff
      end

      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, new_content)

      puts @pastel.green("Updated #{path}")
      true
    rescue => e
      error("Failed to write file: #{e.message}")
    end

    # --------------------------------------------------
    # Ruby Execution
    # --------------------------------------------------

    def ruby_executable_content?(content)
      return false if content.nil? || content.strip.empty?

      return true if content.match?(/if\s+__FILE__\s*==\s*\$0/)
      return true if content.match?(/\bputs\b/)

      line = last_significant_line(content)
      return false unless line

      stripped = line.strip
      return false if stripped.match?(/^(def|class|module|end)\b/)

      stripped.match?(/[A-Za-z_]\w*(\s*\(|\b)/)
    end

    def run_ruby(path)
      full_path = safe_path(path)

      return {
        stdout: "",
        stderr: "File does not exist: #{path}",
        status: nil,
        command: "ruby #{path}",
        skipped: true
      } unless File.exist?(full_path)

      content = File.read(full_path)

      unless ruby_executable_content?(content)
        return {
          stdout: "",
          stderr: "",
          status: nil,
          command: "ruby #{path}",
          skipped: true
        }
      end

      interactive = content.match?(/\bgets\b|\bSTDIN\b|curses|io\/console|readline/)

      if interactive
        puts "▶️  Launching interactive Ruby program (Ctrl+C to exit)..."
        system("ruby", full_path)
        status = $?

        puts "\n▶️  Program exited. Restoring terminal..."

        if File.exist?("/dev/tty")
          STDIN.reopen("/dev/tty")
          STDOUT.reopen("/dev/tty")
          STDERR.reopen("/dev/tty")
        end

        system("stty sane") if system("which stty > /dev/null 2>&1")

    puts "▶️  Returning to Vibecode..."

        return {
          stdout: "",
          stderr: "",
          status: status,
          command: "ruby #{path}",
          skipped: false
        }
      end

      stdout, stderr, status = Open3.capture3("ruby #{full_path}", chdir: @root)

      {
        stdout: stdout,
        stderr: stderr,
        status: status,
        command: "ruby #{path}",
        skipped: false
      }
    rescue => e
      {
        stdout: "",
        stderr: e.message,
        status: nil,
        command: "ruby #{path}",
        skipped: false
      }
    end

    # --------------------------------------------------
    # Filename Suggestions
    # --------------------------------------------------

    def suggest_filename(task_description)
      prompt = task_description.to_s.downcase

      return "hello_world.rb" if prompt.include?("hello world")
      return "greet.rb" if prompt.match?(/\bgreet\b/)

      preferred = %w[
        greet hello world user server client parser json api http config file data
      ]
      stopwords = %w[
        a an the to for of and in on with from into is are be create build make write
        ruby method function class module script program app code that this
      ]

      words = prompt.scan(/[a-z0-9]+/)
      words = words.reject { |w| stopwords.include?(w) }

      if words.include?("hello") && words.include?("world")
        return "hello_world.rb"
      end

      picked = []
      preferred.each do |w|
        picked << w if words.include?(w)
        break if picked.size >= 3
      end

      if picked.empty?
        words.each do |w|
          picked << w
          break if picked.size >= 3
        end
      end

      return "main.rb" if picked.empty?

      "#{picked.uniq.first(3).join("_")}.rb"
    end

    # --------------------------------------------------
    # Directory Tree Snapshot
    # --------------------------------------------------

    def tree(max_depth: 3)
      output = []

      Dir.glob("**/*", base: @root).each do |path|
        depth = path.count(File::SEPARATOR)
        next if depth > max_depth
        next if path.start_with?(".git")

        output << path
      end

      output.sort.join("\n")
    end

    # --------------------------------------------------
    # Safety Helpers
    # --------------------------------------------------

    private

    def last_significant_line(content)
      content.lines.reverse_each do |line|
        stripped = line.strip
        next if stripped.empty?
        next if stripped.start_with?("#")
        return line
      end
      nil
    end

    def safe_path(path)
      expanded = File.expand_path(path, @root)
      unless expanded.start_with?(@root)
        raise "Access outside project root is not allowed"
      end
      expanded
    end

    def error(message)
      puts @pastel.red(message)
      nil
    end
  end
end
