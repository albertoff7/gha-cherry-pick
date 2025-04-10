#!/bin/bash -l

# Initial variables and functions

## Date and formats
AHORA='date +"[%Y-%m-%d-%T]"'
separator() { printf %s\\n "----------------------------------------------------------------------";}
logr() { cr='\033[0;31m'; co='\033[0m'; echo -e "${cr} $(eval ${AHORA}) $1 ${co}";}
logg() { cg='\033[0;32m'; co='\033[0m'; echo -e "${cg} $(eval ${AHORA}) $1 ${co}";}
logy() { cg='\033[0;33m'; co='\033[0m'; echo -e "${cg} $(eval ${AHORA}) $1 ${co}";}

## Git config and remote github
git_setup() {
  cat <<- EOF > "$HOME"/.netrc
		machine github.com
		login $GITHUB_ACTOR
		password $GITHUB_TOKEN
		machine api.github.com
		login $GITHUB_ACTOR
		password $GITHUB_TOKEN
EOF
  chmod 600 "$HOME"/.netrc

  git config --global user.email "$GITBOT_EMAIL"
  git config --global user.name "$GITHUB_ACTOR"
  git config --global --add safe.directory /github/workspace
}

## Initial executions
separator 
figlet -t -k "DevSecOps" && echo ""
logy "Starting github action..."
logy "Purpose: Create Pull Request with cherry-pick"
logy "Autor: MS DevSecOps BMES team"
separator

## Safe directory
logy "Work around permission issue"
git config --global --add safe.directory /github/workspace

## Branchs
logy "We use INPUT_PR_BRANCH:$INPUT_PR_BRANCH"
logy "This is the commit for cherry-pick GITHUB_SHA:$GITHUB_SHA"
PR_BRANCH="auto-$INPUT_PR_BRANCH-$GITHUB_SHA-$(date +%s)"
PR_BRANCH_MAIN="auto-$INPUT_PR_BRANCH_MAIN-$GITHUB_SHA-$(date +%s)"
logy "The name of branch PR_BRANCH:$PR_BRANCH"
logy "The name of branch PR_BRANCH_MAIN:$PR_BRANCH_MAIN"

## Check autocommit
MESSAGE=$(git log -1 "$GITHUB_SHA" | grep -c "AUTO")
logy "MESSAGE:$MESSAGE"
if [[ "$MESSAGE" -gt 0 ]]; then logr"Autocommit, NO ACTION"; exit 0; fi

## Get the last commit
LAST_COMMIT=$(git log -1)
logy "This is the LAST COMMIT:$LAST_COMMIT"
logy "GIT setup execution..."
git_setup

## Fast fetch limited depth
logy "GIT fetch origin"
git fetch origin "${GITHUB_SHA}" --depth=2

## Get the title for PR
logy "Getting PR tittle"
PR_TITLE=$(git log -1 --format="%s" "$GITHUB_SHA")
logy "PR tittle is PR_TITLE:$PR_TITLE"

## Add GITHUB_SHA to the PR body
INPUT_PR_BODY=$(printf "%s\n\nThis PR/issue was created by cherry-pick action from commit %s.", "${INPUT_PR_BODY}", "${GITHUB_SHA}")
logy "This is the INPUT_PR_BODY:${INPUT_PR_BODY}"

## GIT CMD Core commands
logy "Starting Git core commands ..."
git remote update
if [ $? -eq 0 ]; then logg "[OK] Git remote update"; else logr "[FAIL] Git remote update"; fi
git fetch --all
if [ $? -eq 0 ]; then logg "[OK] Git fetch --all"; else logr "[FAIL] Git fetch --all"; fi

## GIT start with release branch
logy "Git checkout new branch ${PR_BRANCH} from ${INPUT_PR_BRANCH}"
git checkout -b "${PR_BRANCH}" origin/"${INPUT_PR_BRANCH}"
if [ $? -eq 0 ]; then logg "[OK] Git checkout branch created"; else logr "[FAIL] Git checkout branch create"; fi
logy "Git cherry-pick ${GITHUB_SHA}"
git cherry-pick "${GITHUB_SHA}" -m "${INPUT_PR_CHERRY_PARENT}"

## Check the exit code of `git cherry-pick`
if [ $? -eq 0 ]; then
  logg "[OK] git cherry-pick succeeded into ${PR_BRANCH}. We will create a pull request for it."
  git push -u origin "${PR_BRANCH}"
  if [ $? -eq 0 ]; then logg "[OK] Push ${PR_BRANCH}"; else logr "[FAIL] Push failed ${PR_BRANCH}"; fi
  hub pull-request -b "${INPUT_PR_BRANCH}" -h "${PR_BRANCH}" -l "${INPUT_PR_LABELS}" -a "${GITHUB_ACTOR}" -m "${PR_TITLE} to ${INPUT_PR_BRANCH}" -m "${INPUT_PR_BODY}" -r "${GITHUB_ACTOR}"
  if [ $? -eq 0 ]; then logg "[OK] PR created ${PR_TITLE}"; else logr "[FAIL] PR create failed ${PR_TITLE}"; fi
else
  logr "[FAIL] git cherry-pick failed."
  #hub issue create -m "cherry-pick ${PR_TITLE} to branch ${INPUT_PR_BRANCH}" -m "${INPUT_PR_BODY}" -a "${GITHUB_ACTOR}" -l "${INPUT_PR_LABELS}"
fi

## GIT start with master branch
logy "Git checkout new branch ${PR_BRANCH_MAIN} from ${INPUT_PR_BRANCH_MAIN}"
git checkout -b "${PR_BRANCH_MAIN}" origin/"${INPUT_PR_BRANCH_MAIN}"
if [ $? -eq 0 ]; then logg "[OK] Git checkout branch created"; else logr "[FAIL] Git checkout branch create"; fi
logy "Git cherry-pick ${GITHUB_SHA}"
git cherry-pick "${GITHUB_SHA}" -m "${INPUT_PR_CHERRY_PARENT}"

## Check the exit code of `git cherry-pick`
if [ $? -eq 0 ]; then
  logg "[OK] git cherry-pick succeeded into ${PR_BRANCH_MAIN}. We will create a pull request for it."
  git push -u origin "${PR_BRANCH_MAIN}"
  if [ $? -eq 0 ]; then logg "[OK] Push ${PR_BRANCH_MAIN}"; else logr "[FAIL] Push failed ${PR_BRANCH_MAIN}"; fi
  hub pull-request -b "${INPUT_PR_BRANCH_MAIN}" -h "${PR_BRANCH_MAIN}" -l "${INPUT_PR_LABELS}" -a "${GITHUB_ACTOR}" -m "${PR_TITLE} to ${INPUT_PR_BRANCH_MAIN}" -m "${INPUT_PR_BODY}" -r "${GITHUB_ACTOR}"
  if [ $? -eq 0 ]; then logg "[OK] PR created ${PR_TITLE}"; else logr "[FAIL] PR create failed ${PR_TITLE}"; fi
else
  logr "[FAIL] git cherry-pick failed."
  #hub issue create -m "cherry-pick ${PR_TITLE} to branch ${INPUT_PR_BRANCH}" -m "${INPUT_PR_BODY}" -a "${GITHUB_ACTOR}" -l "${INPUT_PR_LABELS}"
fi

separator
logy "Bye bye! This is the end."
