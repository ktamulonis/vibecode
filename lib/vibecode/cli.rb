require "optparse"
require "json"
require "fileutils"
require "tty-prompt"
require "tty-spinner"
require "pastel"

require_relative "ollama_client"
require_relative "agent"

module Vibecode
  class CLI
    CONFIG_DIR  = File.join(Dir.home, ".vibecode")
    CONFIG_PATH = File.join(CONFIG_DIR, "config.json")
    DEFAULT_MODEL = "qwen3-coder:latest"

    def self.start(argv)
      new.run(argv)
    end

    def initialize
      @pastel = Pastel.new
      @prompt = TTY::Prompt.new
      ensure_config!
      @config = load_config
      @ollama = OllamaClient.new
    end

    def run(argv)
      options = parse_options(argv)

      case
      when options[:list]
        list_models
      when options[:use]
        use_model(options[:use])
      when options[:pull]
        pull_model(options[:pull])
      when options[:doctor]
        doctor_check
      else
        interactive_session
      end
    end

    # -------------------------
    # Interactive Agent Session
    # -------------------------
    def interactive_session
      puts @pastel.cyan("Vibecode Agent using model: #{@config['model']}")
      puts @pastel.dim("Type 'exit' to quit.\n\n")

      agent = Vibecode::Agent.new(
        model: @config["model"],
        ollama_client: @ollama,
        root: Dir.pwd
      )

      loop do
        input = @prompt.ask(@pastel.green("vibecode> "), required: false)
        break if input.nil? || input.strip.downcase == "exit"

        spinner = TTY::Spinner.new("[:spinner] Thinking...", format: :dots)
        spinner.auto_spin

        spinner.stop
        agent.handle_user_input(input)
        puts
      end
    end

    # -------------------------
    # Model Commands
    # -------------------------
    def list_models
      models = @ollama.list_models
      puts @pastel.cyan("Installed Ollama Models:\n\n")
      models.each do |m|
        marker = (m == @config["model"]) ? @pastel.green(" (active)") : ""
        puts " - #{m}#{marker}"
      end
    end

    def use_model(model_name)
      unless @ollama.model_installed?(model_name)
        puts @pastel.yellow("Model not found locally. Pulling #{model_name}...")
        pull_model(model_name)
      end

      @config["model"] = model_name
      save_config
      puts @pastel.green("Now using model: #{model_name}")
    end

    def pull_model(model_name)
      success = @ollama.pull_model(model_name)
      puts(success ? @pastel.green("\nModel pulled successfully.") : @pastel.red("\nFailed to pull model."))
    end

    # -------------------------
    # Doctor Check
    # -------------------------
    def doctor_check
      puts @pastel.cyan("Running Vibecode system check...\n\n")
      check("Ollama installed") { system("which ollama > /dev/null 2>&1") }
      check("Ollama server running") { @ollama.server_alive? }
      check("Git installed") { system("which git > /dev/null 2>&1") }
      puts
    end

    def check(label)
      print "#{label.ljust(28)}"
      puts(yield ? @pastel.green("OK") : @pastel.red("MISSING"))
    end

    # -------------------------
    # Config Helpers
    # -------------------------
    def ensure_config!
      FileUtils.mkdir_p(CONFIG_DIR)
      return if File.exist?(CONFIG_PATH)
      File.write(CONFIG_PATH, { model: DEFAULT_MODEL }.to_json)
    end

    def load_config
      JSON.parse(File.read(CONFIG_PATH))
    end

    def save_config
      File.write(CONFIG_PATH, JSON.pretty_generate(@config))
    end

    # -------------------------
    # Options
    # -------------------------
    def parse_options(argv)
      options = {}
      OptionParser.new do |opts|
        opts.on("-list") { options[:list] = true }
        opts.on("-use MODEL") { |m| options[:use] = m }
        opts.on("-pull MODEL") { |m| options[:pull] = m }
        opts.on("-doctor") { options[:doctor] = true }
      end.parse!(argv)
      options
    end
  end
end

