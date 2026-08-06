# Ascender Operator

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Build Status](https://github.com/ctrliq/ascender-operator/workflows/CI/badge.svg?event=push)](https://github.com/ctrliq/ascender-operator/actions)
[![Code of Conduct](https://img.shields.io/badge/code%20of%20conduct-Ansible-yellow.svg)](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html)


An [Ascender](https://github.com/ctrliq/ascender) operator for Kubernetes built with [Operator SDK](https://github.com/operator-framework/operator-sdk) and Ansible.

<!-- Regenerate this table of contents using https://github.com/ekalinin/github-markdown-toc -->
<!-- gh-md-toc --insert README.md -->
<!--ts-->

# Ascender Operator Documentation

The Ascender Operator documentation is now available at https://awx-operator.readthedocs.io/

For docs changes, create PRs on the appropriate files in the /docs folder.

## Contributing

Please visit [our contributing guidelines](https://github.com/ctrliq/ascender-operator/blob/devel/CONTRIBUTING.md).

## Release Process

The first step is to create a draft release. Typically this will happen in the [Stage Release](https://github.com/ansible/awx/blob/devel/.github/workflows/stage.yml) workflow for AWX and you don't need to do it as a separate step.

If you need to do an independent release of the operator, you can run the [Stage Release](https://github.com/ctrliq/ascender-operator/blob/devel/.github/workflows/stage.yml) in the ascender-operator repo. Both of these workflows will run smoke tests, so there is no need to do this manually.

After the draft release is created, publish it and the [Promote Ascender Operator image](https://github.com/ctrliq/ascender-operator/blob/devel/.github/workflows/promote.yaml) will run, which will:

- Publish image to Quay
- Release Helm chart

## Author

This operator was originally built in 2019 by [Jeff Geerling](https://www.jeffgeerling.com) and is now maintained by the Ascender Team

## Code of Conduct

We ask all of our community members and contributors to adhere to the [Ansible code of conduct](http://docs.ansible.com/ansible/latest/community/code_of_conduct.html). If you have questions or need assistance, please reach out to our community team at [codeofconduct@ansible.com](mailto:codeofconduct@ansible.com)

## Get Involved

We welcome your feedback and ideas. The Ascender operator uses the same forum as Ascender itself. Here's how to reach us with feedback and questions:

- Join the [Ascender Community Forum](https://forum.ascender-automation.org/)
