# Contributing to AI Platform Infrastructure

Thank you for your interest in contributing! This is primarily a portfolio project, but improvements and suggestions are welcome.

## How to Contribute

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**
4. **Test your changes**: Run validation and ensure everything works
5. **Commit your changes**: `git commit -m 'Add amazing feature'`
6. **Push to the branch**: `git push origin feature/amazing-feature`
7. **Open a Pull Request**

## Development Guidelines

### Code Style

**Python**:
- Follow PEP 8
- Use Black for formatting
- Use isort for import sorting
- Maximum line length: 120 characters

**Kubernetes Manifests**:
- Use 2-space indentation
- Include resource requests and limits
- Add appropriate labels and annotations
- Validate with `kubectl apply --dry-run=client`

### Testing

Before submitting a PR:

```bash
# Validate Kubernetes manifests
make validate

# Test locally
make setup
make deploy
make test-api
```

### Commit Messages

- Use clear, descriptive commit messages
- Start with a verb (Add, Fix, Update, Remove, etc.)
- Reference issues if applicable

Examples:
- `Add Grafana dashboard for cost tracking`
- `Fix HPA configuration for API Gateway`
- `Update Prometheus rules for SLO alerts`

## What to Contribute

### Ideas for Contributions

- 📊 Additional Grafana dashboards
- 🔒 Enhanced security policies
- 📝 Documentation improvements
- 🧪 Test cases and validation
- 🐛 Bug fixes
- ✨ Feature enhancements

### Areas for Improvement

1. **Observability**: Additional metrics, dashboards, or alerting rules
2. **Security**: Enhanced NetworkPolicies, Pod Security Standards
3. **Documentation**: Tutorials, runbooks, troubleshooting guides
4. **Automation**: Additional scripts, CI/CD improvements
5. **Cost Optimization**: Better resource utilization strategies

## Questions or Issues?

- Open an issue for bugs or feature requests
- Start a discussion for questions or ideas

## Code of Conduct

- Be respectful and constructive
- Welcome newcomers
- Focus on what's best for the project

Thank you for contributing! 🚀
