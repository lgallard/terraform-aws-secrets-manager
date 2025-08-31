---
name: Secrets Manager Deprecation
about: Template for AWS Secrets Manager deprecations discovered by automation
title: 'chore: Handle deprecation of [DEPRECATED_FEATURE]'
labels: ['deprecation', 'breaking-change', 'auto-discovered']
assignees: ''

---

## ⚠️ Deprecation Notice

**Deprecated Feature:** [DEPRECATED_FEATURE]
**AWS Provider Version:** [PROVIDER_VERSION]
**Discovery Date:** [DISCOVERY_DATE]
**Deprecation Date:** [DEPRECATION_DATE]
**Removal Date:** [REMOVAL_DATE]

## 📝 Deprecation Details

[AUTO_GENERATED_DESCRIPTION]

## 🔧 Migration Checklist

- [ ] Identify current usage in module
- [ ] Research recommended replacement
- [ ] Plan migration strategy
- [ ] Update module code to use new approach
- [ ] Add deprecation warnings to variables
- [ ] Update examples to use new patterns
- [ ] Create migration guide for users
- [ ] Update tests to cover new functionality
- [ ] Plan communication strategy for users

## 🚨 Impact Assessment

**Affected Resources:**
- [RESOURCE_LIST]

**Backward Compatibility:**
- [ ] Breaking change required
- [ ] Can maintain backward compatibility with warnings
- [ ] No impact on existing users

## 📚 Migration Resources

- [AWS Migration Guide]([MIGRATION_GUIDE_URL])
- [AWS Provider Documentation]([PROVIDER_DOC_URL])
- [Terraform Upgrade Guide]([UPGRADE_GUIDE_URL])

## 📋 Communication Plan

- [ ] Update CHANGELOG.md with deprecation notice
- [ ] Add migration notes to README.md
- [ ] Consider creating a migration example
- [ ] Plan major version release if breaking change

## 📋 Additional Notes

[AUTO_GENERATED_NOTES]

---
*This issue was automatically created by the Secrets Manager Feature Discovery workflow.*
