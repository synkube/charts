# Contributing to Synkube Charts

## Quick Start

```bash
git clone https://github.com/synkube/charts.git
cd charts
pre-commit install           # Optional: local linting
./scripts/update-deps.sh     # Update chart dependencies
```

## Making Changes

1. Fork the repo and clone your fork
2. Create a branch: `git checkout -b feature/my-feature`
3. Make changes and bump version in `Chart.yaml` ([SemVer](https://semver.org/))
4. Test: `helm lint charts/<chart>` and `./scripts/test-render.sh charts/<chart>`
5. Commit using [Conventional Commits](https://www.conventionalcommits.org/):
   ```
   feat(app-starter): add Gateway API support
   fix(app-extensions): correct NetworkPolicy selector
   ```

## Chart Structure

```
charts/<chart-name>/
├── Chart.yaml        # Metadata
├── values.yaml       # Default values
├── README.md         # Documentation
├── templates/        # K8s manifests
└── test-values/      # Test scenarios (XX-description.yaml)
```

## PR Checklist

- [ ] Chart version bumped
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Pre-commit hooks pass
