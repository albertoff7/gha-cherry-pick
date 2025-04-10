# Cherry-Pick Github Action

Github Action to Cherry Pick commits from a branch (generally, dev) and create a PR on another branch (release).

## Action

* GHA runs on push into the monitored branch (dev)
* Git setup configurations
* Get the last commit SHA
* Config branches names
* Checkout to auto-generated branch
* Cherry Pick from the last commit monitored branch
* Push the branch and create the PR on destination branch (release)
* PR title will be prefixed with `auto-commit/sha-date`

## Example

```
name: Create Pull Request with cherry-pick
on:
  push:
    branches:
      - dev
jobs:
  create_cherry_pick_and_pull_request:
    runs-on: ubuntu-latest
    name: create_cherry_pick_and_pull_request:
    steps:
    - name: checkout
      uses: actions/checkout@v1
    - name: GHA cherry-pick and PR
      uses: albertoff7/gha-cherry-pick@master
      with:
        # This is the branch you want to merge your last cherry-picked commit into.
        pr_branch: 'release'
        # This is the "parent" depth at which cherry-picking do.
        pr_cherry_parent: '1'
      env:
        # Enviroments variables that we need
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        GITBOT_EMAIL: me@me.me
        DRY_RUN: false
```
