# Vibecode

**Vibecode** is a terminal-based AI coding agent powered by local LLMs through [Ollama](https://ollama.com). It can read your project files, propose edits with diffs, and run Git commands — all with your approval.

Think of it as a **local, open-source Codex-style coding assistant** that runs directly in your terminal.

---

## ✨ Features

* 🧠 Uses local coding models via Ollama
* 📂 Reads and understands your current project directory
* ✏️ Proposes file edits with colorized diffs
* 🔒 Asks before modifying files or running Git commands
* 🌿 Git-aware (status, branches, commits, push, etc.)
* 🔄 Switch models anytime

---

## 🧰 Requirements

Before installing Vibecode, make sure you have:

* **Ruby 3.0+**
* **Bundler**
* **Git**
* **Ollama** installed and working

Install Ollama from:

👉 [https://ollama.com/download](https://ollama.com/download)

Start the Ollama server:

```bash
ollama serve
```

---

## 🚀 Local Installation (Development Mode)

From the Vibecode project directory:

```bash
bundle install
chmod +x exe/vibecode
```

Run directly without installing the gem:

```bash
bundle exec exe/vibecode
```

---

## 📦 Install as a Local Gem

From the project root:

```bash
gem build vibecode.gemspec
gem install ./vibecode-*.gem
```

Then you can run from anywhere:

```bash
vibecode
```

---

## 🩺 System Check

Verify everything is connected properly:

```bash
vibecode -doctor
```

You should see:

```
Ollama installed            OK
Ollama server running       OK
Git installed               OK
```

---

## 🤖 Managing Models

### List installed models

```bash
vibecode -list
```

### Use a model (auto-pulls if missing)

```bash
vibecode -use qwen2.5-coder:7b
```

### Manually pull a model

```bash
vibecode -pull deepseek-coder:6.7b
```

Your active model is stored in:

```
~/.vibecode/config.json
```

---

## 💬 Starting an AI Coding Session

From any project directory:

```bash
vibecode
```

You will see:

```
Vibecode Agent using model: qwen2.5-coder:7b
vibecode>
```

Now you can give natural language coding instructions.

Example:

```
vibecode> create a ruby method called greet that prints hello world
```

---

## 🧠 How Vibecode Works

The AI responds using structured instructions that Vibecode turns into real actions.

### AI Can Request to Read Files

Vibecode will load the file and send contents back to the AI.

### AI Can Propose File Changes

You will see a **diff preview** before any file is modified.

You must approve changes before they are applied.

### AI Can Suggest Git Commands

Examples:

* `git status`
* `git checkout -b feature/login`
* `git add .`
* `git commit -m "Add login feature"`
* `git push origin feature/login`

You must approve each command before it runs.

---

## 🔒 Safety Model

Vibecode is **human-in-the-loop by default**.

| Action               | Requires Approval |
| -------------------- | ----------------- |
| Reading files        | ❌                 |
| Editing files        | ✅                 |
| Running Git commands | ✅                 |
| Pushing to remote    | ✅                 |

Vibecode **cannot access files outside your current directory**.

---

## 🗂 Project Awareness

Each time you prompt Vibecode, it automatically sends the AI:

* Your project file tree
* Relevant file contents (when needed)
* Conversation history

This allows the AI to reason about your codebase like a real assistant.

---

## 🛠 Internal Architecture (For Contributors)

| Component      | Responsibility                           |
| -------------- | ---------------------------------------- |
| `CLI`          | Handles commands and interactive session |
| `OllamaClient` | Talks to Ollama HTTP API                 |
| `Agent`        | AI reasoning loop + instruction parsing  |
| `Workspace`    | Safe file reading/writing with diffs     |
| `Git`          | Safe Git command execution               |

---

## 🧪 Example Workflow

1. Start Vibecode in your repo
2. Ask for a feature
3. Vibecode proposes edits
4. You approve
5. Vibecode runs Git commands
6. You review and push

---

## 🧭 Roadmap Ideas

* Streaming model responses
* Auto-approve mode
* Test runner integration
* Linter auto-fix mode
* Pull request description generator

---

## ❤️ Philosophy

Vibecode keeps your code and AI **local, private, and developer-controlled**.

No cloud. No tracking. Just you and your AI pair programmer in the terminal.

---

## 📄 License

MIT License

