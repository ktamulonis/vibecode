require "fileutils"
require "pathname"
require "tty-prompt"
require "pastel"
require "diffy"

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

    def list_files(limit: 200)
      files = Dir.glob("**/*", base: @root)
                 .reject { |f| File.directory?(File.join(@root, f)) }
                 .first(limit)

      files.join("\n")
    end

    # --------------------------------------------------
    # File Writing
    # --------------------------------------------------

    def write_file(path, new_content)
      full_path = safe_path(path)
      old_content = File.exist?(full_path) ? File.read(full_path) : ""

      diff = Diffy::Diff.new(old_content, new_content, context: 3).to_s(:color)

      puts @pastel.yellow("\nProposed changes to #{path}:\n")
      puts diff.empty? ? @pastel.dim("(No changes)") : diff

      approved = @prompt.yes?("Apply these changes?")
      unless approved
        puts @pastel.red("File update cancelled.")
        return false
      end

      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, new_content)

      puts @pastel.green("Updated #{path}")
      true
    rescue => e
      error("Failed to write file: #{e.message}")
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

