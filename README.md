# mcvs-golang-action-taskfile-remote-url-ref-updater

This action will update the `REMOTE_URL_REF` that is defined
[in the MCVS-golang-action Taskfile][mcvs-golang-action] automatically by
creating a Pull Request if a newer version of the MCVS-golang action has been
released. It fetches the latest release tag directly from the GitHub API,
so there is no dependency on Dependabot updating workflow files first.

[mcvs-golang-action]: https://github.com/schubergphilis/mcvs-golang-action

## Usage

Create a
`.github/workflows/mcvs-golang-action-taskfile-remote-url-ref-updater.yml` file
with the following content:

```zsh
---
name: mcvs-golang-action-taskfile-remote-url-ref-updater
"on":
  schedule:
    - cron: 42 6 * * *
permissions:
  contents: write
  pull-requests: write
jobs:
  mcvs-golang-action-taskfile-remote-url-ref-updater:
    runs-on: ubuntu-slim
    steps:
      # yamllint disable rule:line-length
      - uses: schubergphilis/mcvs-golang-action-taskfile-remote-url-ref-updater@v0.2.0
      # yamllint enable rule:line-length
```
