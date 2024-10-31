# Contributing to terraform-aws-materialize

We love your input! We want to make contributing to terraform-aws-materialize as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## We Develop with Github
We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

## Pull Requests
Pull requests are the best way to propose changes to the codebase. We actively welcome your pull requests:

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that pull request!


## Generating Documentation

This module uses [terraform-docs](https://terraform-docs.io/user-guide/introduction/) to generate documentation. To generate the documentation, run the following command from the root of the repository:

```bash
terraform-docs --config .terraform-docs.yml .
```

## Development Process

1. Clone the repository
```bash
git clone https://github.com/MaterializeInc/terraform-aws-materialize.git
```

2. Create a new branch
```bash
git checkout -b feature/your-feature-name
```

3. Make your changes and test them:
```bash
# Format your code
terraform fmt -recursive

# Run linter
tflint

# Test the examples
cd examples/simple
terraform init
terraform plan
```

4. Commit your changes
```bash
git commit -m "Add your meaningful commit message"
```

5. Push to your fork and submit a pull request

## Versioning

We follow [Semantic Versioning](https://semver.org/). For version numbers:

- MAJOR version for incompatible API changes
- MINOR version for added functionality in a backwards compatible manner
- PATCH version for backwards compatible bug fixes

## Cutting a new release

Perform a manual test of the latest code on `main`. See prior section. Then run:

    git tag -a vX.Y.Z -m vX.Y.Z
    git push origin vX.Y.Z

## References

- [Terraform Documentation](https://www.terraform.io/docs)
- [Materialize Documentation](https://materialize.com/docs)
