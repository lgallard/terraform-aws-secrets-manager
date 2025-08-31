---
name: New Secrets Manager Feature
about: Template for new AWS Secrets Manager features discovered by automation
title: 'feat: Add support for [FEATURE_NAME]'
labels: ['enhancement', 'aws-provider-update', 'auto-discovered']
assignees: ''

---

## 📋 Feature Discovery Summary

**Feature Name:** [FEATURE_NAME]
**AWS Provider Version:** [PROVIDER_VERSION]
**Discovery Date:** [DISCOVERY_DATE]
**Resource Type:** [RESOURCE_TYPE]

## 📝 Feature Description

[AUTO_GENERATED_DESCRIPTION]

## 🔧 Implementation Checklist

- [ ] Add to `variables.tf` with proper validation
- [ ] Update `main.tf` with new resource configuration
- [ ] Add to relevant examples in `examples/` directory
- [ ] Update `outputs.tf` if needed
- [ ] Add tests in `test/` directory
- [ ] Update documentation in README.md
- [ ] Verify backward compatibility
- [ ] Test with different provider versions

## 📚 Documentation References

- [AWS Provider Documentation]([PROVIDER_DOC_URL])
- [AWS Service Documentation]([AWS_DOC_URL])

## 🧪 Testing Requirements

- [ ] Unit tests for new functionality
- [ ] Integration tests covering the feature
- [ ] Backward compatibility tests
- [ ] Example validation tests

## 📋 Additional Notes

[AUTO_GENERATED_NOTES]

---
*This issue was automatically created by the Secrets Manager Feature Discovery workflow.*
