# Vibecode

**Vibecode** is a terminal-native AI coding agent powered by local LLMs through **Ollama**.

It can read your project, propose edits with diffs, create new files intelligently, and even run Ruby code it writes — all with your approval.

Think of it as:

> A local, open-source, Codex-style coding assistant that lives in your terminal.

No cloud. No API keys. No data leaving your machine.

---

## ✨ Features

* 🧠 Uses local coding models via **Ollama**
* 📂 Understands your current project directory
* ✏️ Proposes file edits with colorized diffs
* 🆕 Creates smartly named new files (no fake `path/to/file.rb`)
* ▶️ Runs Ruby files automatically when appropriate
* 🔒 Requires approval before writing files
* 🌿 Git integration only when **you** ask for it
* 🔄 Switch models anytime

---

## 🧰 Requirements

You need:

* Ruby **3.0+**
* Git
* Ollama

Install Ollama:

👉 [https://ollama.com/download](https://ollama.com/download)

Start the Ollama server:

```bash
ollama serve
```

---

## 🚀 Install from RubyGems

```bash
gem install vibecode
```

Verify:

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

List installed models:

```bash
vibecode -list
```

Switch models (auto-pulls if missing):

```bash
vibecode -use qwen2.5-coder:7b
```

Manually pull a model:

```bash
vibecode -pull deepseek-coder:6.7b
```

Your active model is stored in:

```
~/.vibecode/config.json
```

---

## 💬 Starting an AI Coding Session

From **any project directory**:

```bash
vibecode
```

You’ll see:

```
Vibecode Agent using model: ...
vibecode>
```

Now you can type natural coding requests.

Example:

```
create a ruby method greet that prints hello world
```

Vibecode will:

1. Show a plan
2. Show a diff preview
3. Ask for approval
4. Create a properly named file like `hello_world.rb`
5. Run the Ruby file automatically
6. Show the output

---

## 🧠 How Vibecode Works

The AI responds using a structured format that Vibecode turns into actions.

### Reading files

If the AI needs to see a file, Vibecode loads it and sends the contents back.

### Creating new files

If the AI wants to edit a file that doesn’t exist, Vibecode generates a smart filename automatically.

### Editing files

You always see a diff before anything is written.

### Running Ruby

If the file contains top-level execution, Vibecode runs:

```bash
ruby filename.rb
```

…and shows the output to both you and the AI.

### Git

Vibecode will **never** run git unless your prompt contains the word `git`.

---

## 🔒 Safety Model

| Action        | Requires Approval                 |
| ------------- | --------------------------------- |
| Reading files | ❌                                 |
| Writing files | ✅                                 |
| Running Ruby  | Automatic (only when appropriate) |
| Running Git   | Only if you ask                   |

Vibecode **cannot access files outside** the current directory.

---

## 🧪 Example Session

```
vibecode> create a ruby method greet that prints hello world
```

Output:

```
Proposed edit for hello_world.rb
+def greet
+  puts "hello world"
+end

Vibecode plans to:
- create file hello_world.rb
- run ruby hello_world.rb
Proceed? (Y/n)
```

After approval:

```
hello world
```

---

## 🛠 Internal Architecture

| Component    | Responsibility                    |
| ------------ | --------------------------------- |
| CLI          | Command handling + session        |
| OllamaClient | Talks to Ollama HTTP API          |
| Agent        | Planning, parsing, execution flow |
| Workspace    | Safe file system + Ruby execution |
| Git          | Safe Git command wrapper          |

---

## ❤️ Philosophy

Vibecode is:

* Local-first
* Developer-controlled
* Human-in-the-loop
* Transparent
* Offline-capable

You stay in charge. The AI assists.

---

## 🧭 Roadmap

Future improvements:

* Streaming model responses
* Session memory
* Auto-approve mode
* Test runner integration
* Linter / formatter mode

---

## 📄 License

MIT License

