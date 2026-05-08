# Security Setup

## Pre-commit Checks

Every commit runs:
1. Branch validation (no direct commits to main)
2. Biome linting + formatting
3. TypeScript type checking
4. **Gitleaks** - secret detection
5. **PII check** - personal information detection
6. Emoji detection

## Gitleaks

Detects secrets, API keys, tokens in code.

**Install:**
```bash
# macOS
brew install gitleaks

# Linux
wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz
tar -xzf gitleaks_8.18.0_linux_x64.tar.gz
sudo mv gitleaks /usr/local/bin/
```

**Manual scan:**
```bash
gitleaks detect --no-git --redact
```

## PII Check

Prevents committing personal information (hostnames, names, phone numbers).

**Configure:**
Edit `.config/.pii` with your patterns:
```
# Hostnames
my-laptop
my-laptop\.local

# Names
john
jane

# Phone patterns
\+31\s?[0-9]{1,3}\s?[0-9]{3,4}\s?[0-9]{4}
```

**Note:** `.config/.pii` is in `.gitignore` - each developer maintains their own.

## Setup

```bash
make install  # Installs hooks + dependencies
```

Pre-commit hook is symlinked from `.config/pre-commit` to `.git/hooks/pre-commit`.
