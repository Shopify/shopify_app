# GitHub Issue Investigation Report Template

When producing the final report, follow this structure exactly.

## Issue Overview
- **URL**: [issue URL]
- **Title**: [issue title]
- **Author**: [author username]
- **Created**: [date]
- **Current Status**: [open/closed]
- **Repository**: [repo-name]
- **Reported Version**: [version from issue]
- **Latest Major Version**: [current latest major version]
- **Version Status**: [Actively Maintained / Not Maintained]
- **Affected Package(s)**: [e.g., `packages/apps/shopify-app-remix`]

## Issue Category
Check the single most applicable category:
- [ ] Feature Request
- [ ] Technical Limitation Request (Requires Business Case)
- [ ] Bug Report (Valid - Latest Version)
- [ ] Bug Report (Won't Fix - Older Version)
- [ ] Security Vulnerability (May Backport)
- [ ] Documentation Request
- [ ] General Question
- [ ] Other: [specify]

## Reproduction Status
- [ ] Reproduced on latest version
- [ ] Cannot reproduce on latest (may already be fixed)
- [ ] Cannot reproduce (insufficient information from reporter)
- [ ] Not applicable (feature request / question)

## Summary
[2-3 paragraph summary of the issue, including what the user is trying to achieve and what problem they're facing]

**Issue Status**: [New Issue / Duplicate of #XXX / Related to #XXX, #YYY]

## Repository Context

### Project Overview
[Brief description of what the repository does]

### Relevant Code Areas
[List files, modules, or components related to this issue]

### Code Analysis
[Your findings from examining the codebase]

## Technical Details
[Any specific technical information gathered from code review]

## Related Information
- **Similar/Duplicate Issues**: [List all similar issues found with full URLs, including closed ones]
- **Related PRs**: [provide full URLs, e.g., https://github.com/owner/repo/pull/456]
- **Previous Attempts**: [Document any previous attempts to address this issue]
- **Existing Workarounds**: [Note any workarounds mentioned in similar issues]
- **Documentation gaps**: [if identified]

## Recommendations

### Version-Based Approach

#### For issues in older versions:
- **Primary**: Recommend upgrading to the latest major version [specify version]
- **Secondary**: Provide workarounds if possible, but clearly state no fixes will be backported
- **Communication**: Explicitly state that the reported version is no longer maintained

#### For issues in latest version:
[Your professional recommendations for addressing this issue]

### For Technical Limitation Requests
When the issue involves a fundamental technical limitation or architectural constraint:

#### Business Case Understanding
**Recommended follow-up questions to the issue creator:**
- What is the specific business use case you're trying to solve?
- Have you considered [alternative approaches]? What are the constraints preventing their use?
- What would be the business impact if this limitation isn't addressed?

#### Provide Context
- Explain why the limitation exists (technical/architectural reasons)
- Reference similar requests with full URLs (e.g., https://github.com/owner/repo/issues/123)
- Suggest viable workarounds with pros/cons for each approach

### Documentation Updates
If the issue could be resolved by updating the documentation, recommend the specific documentation file and section that needs updating.

## Additional Notes
[Any other relevant observations]
