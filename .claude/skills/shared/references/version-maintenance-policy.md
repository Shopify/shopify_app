# Version Maintenance Policy

## Policy Overview
- **Only the latest major version is actively maintained**
- Previous major versions do NOT receive updates except for severe security vulnerabilities
- Bug fixes and features are only implemented in the current major version

## Bug Classification Rules

### For issues in non-latest major versions:
- **NOT a valid bug** — Regular bugs/issues in older versions (won't be fixed)
- **Valid bug** — ONLY severe security vulnerabilities that warrant backporting

### For issues in latest major version:
- **Valid bug** — All legitimate bugs and issues

## PR Implications
- PRs targeting an unmaintained major version should be flagged
- Recommend contributors re-target their fix to the latest major version
- Exception: severe security vulnerability backports
