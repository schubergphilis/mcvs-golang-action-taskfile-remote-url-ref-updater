#!/bin/bash

set -xeuo pipefail

readonly PR_TITLE="build(deps): mcvs-golang-action remote_url_ref update in taskfile"

generate_pr_body_with_updates() {
  local new_version="${1}"

  export PR_BODY="Update mcvs-golang-action version remote_url_ref in taskfile to: ${new_version}"
  echo "PR_BODY: ${PR_BODY}"
}

extract_mcvs_golang_action_version_from_github_workflows_golang() {
  grep -oE 'schubergphilis/mcvs-golang-action@[^ ]+' .github/workflows/golang.yml \
    | head -n1 \
    | sed -E 's/.*@//'
}

update_mcvs_golang_action_ref_in_taskfile() {
  local new_version="${1}"

  if [ -z "${new_version}" ]; then
    echo "No version provided to update_mcvs_golang_action_ref_in_taskfile" >&2
    return 1
  fi

  yq -i ".vars.REMOTE_URL_REF = \"${new_version}\"" Taskfile.yml
}

checkout_branch_required_to_apply_package_version_updates() {
  git fetch -p -P

  if (git ls-remote --exit-code --heads origin refs/heads/${MCVS_GOLANG_ACTION_TASKFILE_REMOTE_URL_REF_UPDATER_BRANCH}); then
    echo "Branch '${MCVS_GOLANG_ACTION_TASKFILE_REMOTE_URL_REF_UPDATER_BRANCH}' already exists."
    git checkout ${MCVS_GOLANG_ACTION_TASKFILE_REMOTE_URL_REF_UPDATER_BRANCH}

    return
  fi

  git checkout -b ${MCVS_GOLANG_ACTION_TASKFILE_REMOTE_URL_REF_UPDATER_BRANCH}
}

check_label_exists() {
  local label_name="$1"

  LABEL_EXISTS=$(
    gh label list --json name |
    jq -r '
      .[] |
      select(.name == "'"$label_name"'") |
      .name
    '
  )
  if [ -z "${LABEL_EXISTS}" ]; then
    echo "label: '${label_name}' does NOT exist"
    return 1
  fi
}

github_labels() {
  if ! check_label_exists ${DEPENDENCIES_LABEL}; then
    gh label create "${DEPENDENCIES_LABEL}" \
      --color "#0366d6" \
      --description "Pull requests that update a dependency file"
  fi

  labels=("${DEPENDENCIES_LABEL}")
  echo "Labels:"

  for label in "${labels[@]}"; do
    echo "'$label'"
  done
}

commit_and_push_changes() {
  if [ -n "$(git status --porcelain)" ]; then echo "There are uncommitted changes."; else echo "No changes to commit." && return; fi
    git add .
    git config user.name github-actions[bot]
    git config user.email 41898282+github-actions[bot]@users.noreply.github.com

  if ! git commit -m "${PR_TITLE}"; then git commit --amend --no-edit; fi
    git push origin ${MCVS_GOLANG_ACTION_TASKFILE_REMOTE_URL_REF_UPDATER_BRANCH} --force-with-lease
}

create_or_edit_pr() {
  if gh pr list --json title | jq -e '.[] | select(.title | test("build\\(deps\\): weekly update package versions that cannot be updated by dependabot"))'; then
    echo "PR exists already. Updating the 'title' and 'description'..."

    gh pr edit ${MCVS_GOLANG_ACTION_TASKFILE_REMOTE_URL_REF_UPDATER_BRANCH} \
      --body "${PR_BODY}" \
      --title "${PR_TITLE}"

    return
  fi

  echo "creating pr..."
  label_args=()
  for label in "${labels[@]}"; do
    label_args+=(--label "$label")
  done

  gh pr create \
    --base main \
    --body "${PR_BODY}" \
    --fill \
    --head "${MCVS_GOLANG_ACTION_TASKFILE_REMOTE_URL_REF_UPDATER_BRANCH}" \
    --title "${PR_TITLE}" \
    "${label_args[@]}"
}

main() {
  checkout_branch_required_to_apply_package_version_updates

  local version
  version="$(extract_mcvs_golang_action_version_from_github_workflows_golang)"
  if [ -z "${version}" ]; then
    echo "Could not extract version from workflow!" >&2
    exit 1
  fi

  update_mcvs_golang_action_ref_in_taskfile "${version}"
  generate_pr_body_with_updates "${version}"
  github_labels
  commit_and_push_changes
  create_or_edit_pr
}

main
