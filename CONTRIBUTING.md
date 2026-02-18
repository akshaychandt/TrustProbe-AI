# Contributing to TrustProbe AI

Thank you for your interest in contributing to TrustProbe AI! 🛡️

## How to Contribute

### Reporting Bugs

1. Check existing [Issues](https://github.com/akshaychandt/TrustProbe-AI/issues) to avoid duplicates
2. Create a new issue with:
   - **Title**: Clear, concise description
   - **Steps to reproduce**: Detailed steps
   - **Expected behavior**: What should happen
   - **Actual behavior**: What actually happens
   - **Screenshots**: If applicable
   - **Environment**: Flutter version, browser, OS

### Suggesting Features

Open an issue with the `enhancement` label and describe:
- The problem your feature solves
- Your proposed solution
- Any alternatives you've considered

### Pull Requests

1. **Fork** the repository
2. **Create** a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Follow** the existing code structure (Stacked MVVM pattern)
4. **Write tests** for new functionality
5. **Run** existing tests to ensure nothing breaks:
   ```bash
   flutter test
   ```
6. **Analyze** the code for issues:
   ```bash
   flutter analyze
   ```
7. **Commit** using [Conventional Commits](https://www.conventionalcommits.org/):
   ```
   feat: add new risk factor for encoded URLs
   fix: correct scoring for trusted subdomains
   docs: update detection algorithm documentation
   test: add tests for brand impersonation detection
   ```
8. **Push** and open a Pull Request

## Code Style

- Follow the Dart [style guide](https://dart.dev/effective-dart/style)
- Use the linter rules defined in `analysis_options.yaml`
- Add doc comments (`///`) to all public APIs
- Use `const` constructors where possible
- Prefer switch expressions and arrow functions (Dart 3+)

## Architecture Guidelines

- **Views** should contain NO business logic
- **ViewModels** manage state and orchestrate services
- **Services** contain reusable business logic
- Use `locator<T>()` for dependency injection
- Keep services independent and testable

## Adding New Risk Factors

1. Add the check in `PhishingService._calculateRiskScore()`
2. Add the human-readable reason in `PhishingService._generateReason()`
3. Write a test in `test/phishing_service_test.dart`
4. Update the README detection algorithm table

## Questions?

Feel free to open an issue or reach out to the maintainer.

---

Thank you for making TrustProbe AI better! 🚀
