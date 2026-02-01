require "httparty"
require "json"

module Vibecode
  class OllamaClient
    include HTTParty
    base_uri "http://localhost:11434"

    def initialize
      @headers = { "Content-Type" => "application/json" }
    end

    # -----------------------------
    # Chat with Model
    # -----------------------------
    def chat(model, system_prompt, user_input)
      body = {
        model: model,
        stream: false,
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: user_input }
        ]
      }

      response = self.class.post("/api/chat", headers: @headers, body: body.to_json)

      unless response.success?
        return "Error talking to Ollama: #{response.code} #{response.body}"
      end

      parsed = JSON.parse(response.body)
      parsed.dig("message", "content") || "(No response from model)"
    rescue Errno::ECONNREFUSED
      "Cannot connect to Ollama. Is it running? Try: `ollama serve`"
    rescue => e
      "Ollama error: #{e.message}"
    end

    # -----------------------------
    # List Installed Models
    # -----------------------------
    def list_models
      response = self.class.get("/api/tags")

      return [] unless response.success?

      parsed = JSON.parse(response.body)
      parsed.fetch("models", []).map { |m| m["name"] }
    rescue
      []
    end

    def model_installed?(model_name)
      list_models.include?(model_name)
    end

    # -----------------------------
    # Pull Model
    # -----------------------------
    def pull_model(model_name)
      uri = URI("#{self.class.base_uri}/api/pull")

      req = Net::HTTP::Post.new(uri, @headers)
      req.body = { name: model_name, stream: true }.to_json

      Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req) do |res|
          unless res.is_a?(Net::HTTPSuccess)
            puts "Failed to start model pull"
            return false
          end

          res.read_body do |chunk|
            begin
              data = JSON.parse(chunk)
              show_pull_progress(data)
            rescue JSON::ParserError
              # ignore incomplete chunks
            end
          end
        end
      end

      true
    rescue => e
      puts "Error pulling model: #{e.message}"
      false
    end

    def show_pull_progress(data)
      if data["status"]
        print "\r#{data['status'].ljust(60)}"
      elsif data["completed"] && data["total"]
        percent = (data["completed"].to_f / data["total"] * 100).round(1)
        print "\rDownloading... #{percent}%".ljust(60)
      end
    end

    # -----------------------------
    # Health Check
    # -----------------------------
    def server_alive?
      response = self.class.get("/")
      response.code == 200 || response.code == 404
    rescue
      false
    end
  end
end

