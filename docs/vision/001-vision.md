# ADR-001: Vision

**Status:** Accepted  
**Date:** 2026-05-09  
**Context:** V-Model Layer 1 - Vision

## Context

We need a unified terminal interface to access calendar, email, and tasks across multiple providers (Google, Microsoft, Proton, Apple) without leaving the command line.

## Decision

Build workspace-tui as a CLI tool that:
- Works over SSH (no GUI required)
- Supports multi-provider integration
- Provides both human-readable and AI-parseable output
- Maintains security through local credential storage
- Enables workflow automation through scriptable commands

## Consequences

**Positive:**
- Single tool for all workspace management
- Works in any terminal environment
- AI agents can integrate seamlessly
- Scriptable for automation

**Negative:**
- Requires OAuth setup per provider
- Limited by terminal capabilities
- Must handle multiple authentication flows

## Related

- [ADR-003: Interface Segregation](../adr/003-interface-segregation.md)
- [ADR-006: Config File Credentials](../adr/006-config-file-credentials.md)
- [Architecture Overview](../architecture/target-architecture.md)
