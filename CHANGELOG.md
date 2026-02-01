# Changelog

All notable changes to this project will be documented in this file.

---

## [0.0.1] - Initial Release

### Added
- Terminal-native AI coding agent powered by Ollama
- Safe file editing with colorized diff previews
- Smart filename generation for new files (no fake paths)
- Automatic Ruby execution with output feedback
- Human-in-the-loop approval before file writes
- Git integration only when explicitly requested by the user
- Model management (`-list`, `-use`, `-pull`)
- Local configuration stored in `~/.vibecode/config.json`
- System diagnostics with `vibecode -doctor`

### Fixed
- Eliminated infinite edit/read loops
- Removed aggressive and unwanted git behavior
- Fixed TTY prompt approval issues
- Corrected agent execution order (plan → diff → approve → write → run)

### Notes
This is the first stable release of Vibecode.  
The focus is correctness, safety, and predictable behavior for local AI coding.

Future versions will add streaming responses, session memory, and expanded tooling.

