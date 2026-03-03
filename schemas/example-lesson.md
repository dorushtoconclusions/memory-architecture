---
type: lesson
date: 2026-03-02
category: process
tags: [research, tools, documentation]
trigger: about-to-recommend-tool
severity: high
---

# Research Order Before Recommending

**Trigger:** About to recommend a tool, config, or command.

**Rule:** Follow research order: (1) tool's own README/docs, (2) `--help`/man page, (3) GitHub issues, (4) web search, (5) sub-agent. Never skip to web search before reading local docs.

**Evidence:** iMessage TCC incident 2026-03-02 — web searches and sub-agent both returned wrong advice; the imsg README had the correct answer.

**Boundary:** General knowledge questions unrelated to a specific tool.
