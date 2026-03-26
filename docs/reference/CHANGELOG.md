# Changelog

All notable changes to this project will be documented here.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.1.0](https://github.com/rommelporras/kiro-config/releases/tag/v0.1.0) - 2026-03-26

First release of kiro-config — opinionated global Kiro CLI configuration with 11 workflow skills, 3-layer security, and engineering steering.

### Added
- 11 auto-activating workflow skills: commit, push, explain-code, brainstorming, writing-plans, test-driven-development, systematic-debugging, verification-before-completion, receiving-code-review, dispatching-parallel-agents, subagent-driven-development
- 3-layer security: PreToolUse hooks (secret scanning, sensitive file protection, destructive command blocking), denied paths, denied commands
- Engineering steering rules: evidence over assertions, TDD, plan before building, conventional commits
- Base agent (`base.json`) with pre-approved read-only tools and security hooks
- MCP servers: Context7, AWS Documentation, AWS Diagram
- Documentation: install checklist, IDE + WSL2 setup, troubleshooting, skill catalog, security model, custom agent guide
