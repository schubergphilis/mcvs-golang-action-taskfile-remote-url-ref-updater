# mcvs-golang-action-taskfile-remote-url-ref-updater

This action will update the `REMOTE_URL_REF` that is defined
[in the MCVS-golang-action Taskfile](mcvs-golang-action) automatically by
creating a Pull Request if a newer version of the MCVS-golang action has been
released. This will prevent that one will forget to update the Taskfile once
Dependabot has been updated it.

[mcvs-golang-action]: https://github.com/schubergphilis/mcvs-golang-action
