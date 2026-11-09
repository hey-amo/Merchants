---
description: Describe when these instructions should be loaded by the agent based on task context
# applyTo: 'Describe when these instructions should be loaded by the agent based on task context' # when provided, instructions will automatically be added to the request context when the pattern matches an attached file
---

<!-- Tip: Use /create-instructions in chat to generate content with agent assistance -->

Hard rule instruction: All pull requests should be against `working-branch`, NEVER make a pull request against `main`

Soft rule instruction: Feature branches should be named using the format `feature/<fr<#number>-<feature-name>>`
