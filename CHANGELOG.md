# Changelog

## 0.2.0 — 2026-02-15

- Add Chart.js charting to query results with a Table/Chart toggle
- Auto-detect chart type based on column data (line for dates, pie for low-cardinality categories, bar for high-cardinality, scatter for numeric pairs)
- Chart controls for switching type, X axis, and Y axis columns
- Dark-themed charts matching the existing UI

## 0.1.3 — 2026-02-11

- Migrations are now copied into the host app via `rails generate query_lens:install` instead of being loaded automatically from the engine ([#6](https://github.com/bryanbeshore/query_lens/pull/6))
- Add upgrade note to README for users with existing tables

## 0.1.2 — 2026-02-09

- Fix: follow-up questions no longer generate unwanted new SQL queries — the LLM now responds conversationally when appropriate ([#2](https://github.com/bryanbeshore/query_lens/issues/2))
- Fix: assistant responses without SQL are now preserved in conversation history, maintaining context for subsequent messages

## 0.1.1 — 2026-02-09

- Fix: include `db/` directory in gemspec so migrations are shipped with the gem ([#1](https://github.com/bryanbeshore/query_lens/issues/1))

## 0.1.0 — 2026-02-07

Initial release.

- Natural language to SQL conversion powered by RubyLLM (OpenAI, Anthropic, Gemini, Ollama, and more)
- Automatic database schema introspection with caching
- Smart two-stage schema handling for large databases (50+ tables)
- Read-only query execution with multiple safety layers
- Saved queries organized into projects
- Conversation history with auto-save
- Interactive follow-up questions with context
- Editable SQL editor with syntax highlighting
- Sortable results tables
- Configurable authentication, timeouts, row limits, and excluded tables
- Audit logging for all query activity
- Zero frontend dependencies (self-contained CSS, vanilla JS)
- Active Admin mounting support
