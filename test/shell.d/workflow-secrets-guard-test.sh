#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

[[ -x /usr/bin/python3 ]] || fail "the system Python is available at /usr/bin/python3"
/usr/bin/python3 -I -c 'import yaml' 2>/dev/null || fail "required Python module is available: yaml"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

cat >"$test_tmp/guard.py" <<'EOF'
import glob
import os
import re
import sys

import yaml

# Each of these only accepts main (RELEASING.md, "Secrets"). A secret anywhere
# else can be read by a workflow edited on any branch or tag.
MAIN_ONLY_ENVIRONMENTS = {"release", "docker-hub", "maitri-pkgs"}
MAIN_GATE = "github.ref == 'refs/heads/main'"

# Where a shell command starts, any VAR=value prefixes, and the wrappers and
# interpreters that run the word after them.
COMMAND = r"(?:^|[;&|(]|\$\(|\b(?:then|do|else)\b|\{)\s*(?:[A-Za-z_][A-Za-z0-9_]*=(?:\"[^\"]*\"|'[^']*'|[^\s$()\"']*)\s+)*"
WRAPPER = r"(?:(?:sudo|env|exec|command|nohup|xargs|timeout)\s+(?:-\S+\s+)*)*"
INTERPRETER = r"(?:bash|sh|source|\.|python3?|node|perl)\s+(?:-\S+\s+)*"

workflows_dir = os.path.join(sys.argv[1], ".github", "workflows")


def ok(description):
    print(f"ok - {description}")


def check(condition, description, detail=""):
    if not condition:
        if detail:
            print(detail, file=sys.stderr)
        print(f"not ok - {description}", file=sys.stderr)
        sys.exit(1)


def load(path):
    with open(path) as f:
        workflow = yaml.safe_load(f)
    # PyYAML reads the bare key `on` as true.
    workflow["on"] = workflow.pop(True, workflow.get("on"))
    return workflow


def expressions(value):
    return re.findall(r"\$\{\{(.*?)\}\}", yaml.safe_dump(value, width=1 << 20))


def sees_secret(value):
    for expression in expressions(value):
        rest = re.sub(r"secrets\.GITHUB_TOKEN\b", "", expression)
        if re.search(r"\bsecrets\b", rest):
            return True
    return False


def gated_on_main(job):
    condition = str(job.get("if", "")).strip()
    wrapped = re.fullmatch(r"\$\{\{(.*)\}\}", condition, re.S)
    if wrapped:
        condition = wrapped.group(1).strip()
    if condition == MAIN_GATE:
        return True
    rest = condition[len(MAIN_GATE):] if condition.startswith(MAIN_GATE) else ""
    return re.match(r"\s*&&", rest) is not None and "||" not in rest


def environment(job):
    value = job.get("environment")
    return value.get("name") if isinstance(value, dict) else value


def steps(job):
    return job.get("steps") or []


def first_step(job, predicate):
    return next((i for i, step in enumerate(steps(job)) if predicate(step)), None)


def script(step):
    return (step.get("run") or "").replace("\\\n", " ")


def runs(step, text):
    return text in script(step)


def uses(step, action):
    return (step.get("uses") or "").startswith(action + "@")


def runs_a_file_it_did_not_check_out(step):
    for line in script(step).splitlines():
        if re.search(COMMAND + WRAPPER + r"[\"']?(?:\$|/|\.\.?/|~)", line):
            return line
        if re.search(COMMAND + WRAPPER + INTERPRETER + r"(?![\"']?tools/)", line):
            return line
    return None


workflows = {os.path.basename(path): load(path) for path in sorted(glob.glob(os.path.join(workflows_dir, "*.yml")))}
check(workflows, "the workflows are found", workflows_dir)

for name, workflow in workflows.items():
    check(not sees_secret(workflow.get("env") or {}), f"{name}: the workflow-level env holds no secret")
    for job_name, job in (workflow.get("jobs") or {}).items():
        where = f"{name}: {job_name}"
        check("secrets" not in job, f"{where} passes no secrets on to another workflow")
        if not sees_secret(job):
            continue
        check(environment(job) in MAIN_ONLY_ENVIRONMENTS, f"{where} reads a secret, so it runs in a main-only environment",
              f"environment: {environment(job)!r}, expected one of {sorted(MAIN_ONLY_ENVIRONMENTS)}")
        check(gated_on_main(job), f"{where} only runs on main, and nothing in its condition can get around that",
              f"if: {job.get('if')!r}")
        check(not sees_secret(job.get("env") or {}), f"{where} keeps its secrets in the steps that use them")
        for step in steps(job):
            detail = yaml.safe_dump(step)
            check(not expressions(step.get("run") or ""), f"{where}: no expression is expanded inside a run script", detail)
            action = step.get("uses")
            check(action is None or re.fullmatch(r"[A-Za-z0-9-]+/[A-Za-z0-9._/-]+@[0-9a-f]{40}", action),
                  f"{where} only uses actions pinned to a commit, never a local one", detail)
            if uses(step, "actions/checkout"):
                check(not {"ref", "repository"} & set(step.get("with") or {}), f"{where} only checks out main", detail)
            if uses(step, "actions/download-artifact"):
                check(str((step.get("with") or {}).get("path", "")).startswith("${{ runner.temp }}/"),
                      f"{where} downloads artifacts outside the checkout", detail)
            check(not re.search(r"\bgit\b[^;&|\n]*\s(?:checkout|switch|restore|worktree)\b", script(step)),
                  f"{where} never moves its checkout off main", detail)
            check(not runs_a_file_it_did_not_check_out(step),
                  f"{where} only runs commands from PATH and main's tools/", runs_a_file_it_did_not_check_out(step))
ok("every secret lives in a job that runs only on main, in a main-only environment, and runs only main's code")

for name, workflow in workflows.items():
    for job_name, job in (workflow.get("jobs") or {}).items():
        for step in steps(job):
            injected = [e for e in expressions(step.get("run") or "") if re.search(r"\binputs\b", e)]
            check(not injected, f"{name}: {job_name} hands inputs to run scripts through env", step.get("run"))
ok("workflow inputs never reach a run script as code")

build_iso = workflows["build-iso.yml"]
check(set(build_iso["on"]) == {"workflow_dispatch"}, "build-iso.yml only runs on workflow_dispatch", str(build_iso["on"]))
check(set(build_iso["jobs"]) == {"build", "publish"}, "build-iso.yml has a build job and a publish job")
build, publish = build_iso["jobs"]["build"], build_iso["jobs"]["publish"]

check("environment" not in build and not sees_secret(build), "the build job has no environment and no secrets")
check(build.get("permissions") == {"contents": "read"}, "the build job can only read the repository", str(build.get("permissions")))
tag_check = first_step(build, lambda s: runs(s, 'tools/check-release-tag.sh "$RELEASE_TAG"'))
check(tag_check is not None and steps(build)[tag_check].get("id") == "tag", "the build job checks the tag")
tag_step = steps(build)[tag_check]
check(tag_step.get("if") == "inputs.release_tag != ''" and runs(tag_step, '[[ $GITHUB_REF == "refs/heads/main" ]]'),
      "a release build only starts on main")
check(runs(tag_step, 'echo "commit=$(git rev-parse "refs/tags/$RELEASE_TAG^{commit}")" >>"$GITHUB_OUTPUT"'),
      "the tag check resolves the commit the release builds")
trees = [i for i, s in enumerate(steps(build)) if uses(s, "actions/checkout") and "ref" in (s.get("with") or {})]
releases = [i for i in trees if steps(build)[i].get("if") == "inputs.release_tag != ''"]
check(len(releases) == 1 and steps(build)[releases[0]]["with"]["ref"] == "${{ steps.tag.outputs.commit }}",
      "a release build checks out the commit the tag check resolved, not the tag's name",
      yaml.safe_dump([steps(build)[i] for i in trees]))
check(all(i in releases or steps(build)[i].get("if") == "inputs.release_tag == ''" for i in trees),
      "only a test build checks out the ref it was given")
docker = first_step(build, lambda s: runs(s, "docker run"))
check(docker is not None and tag_check < min(trees) and max(trees) < docker,
      "the build job checks the tag before it checks out or builds the tag's tree")
record = first_step(build, lambda s: s.get("id") == "tree")
check(record is not None and max(trees) < record < docker and runs(steps(build)[record], "commit=$(git -C src rev-parse HEAD)")
      and runs(steps(build)[record], '$commit == "$TAG_COMMIT"'),
      "the build job records the commit it checked out, before it builds")
check(build.get("outputs") == {"commit": "${{ steps.tree.outputs.commit }}"}, "the build job hands on the commit it built",
      str(build.get("outputs")))
upload = first_step(build, lambda s: uses(s, "actions/upload-artifact"))
check(upload is not None and steps(build)[upload]["with"].get("overwrite") is True,
      "re-running the whole workflow replaces the ISO artifact instead of failing on its name")
ok("the build job runs the tree it builds with no environment, no secrets and a read-only token")

check(publish.get("needs") == "build", "the publish job runs after the build")
check(publish.get("if") == f"{MAIN_GATE} && inputs.release_tag != ''", "the publish job only runs for a release, on main", str(publish.get("if")))
check(environment(publish) == "docker-hub", "the publish job is the one in the docker-hub environment")
guard = first_step(publish, lambda s: runs(s, 'tools/check-release-tag.sh "$TAG"'))
secret = first_step(publish, sees_secret)
check(None not in (guard, secret) and guard < secret, "the publish job checks the tag before any step that sees a secret")
guard_step = steps(publish)[guard]
check((guard_step.get("env") or {}).get("BUILT_COMMIT") == "${{ needs.build.outputs.commit }}"
      and runs(guard_step, 'commit=$(git rev-parse "refs/tags/$TAG^{commit}")')
      and runs(guard_step, '[[ $commit == "$BUILT_COMMIT" ]] ||'),
      "the publish job refuses the ISO unless the tag still points at the commit it was built from")
check(yaml.safe_dump(publish).count("needs.build") == 1, "the publish job takes nothing else from the build job but the artifact")
check(not any(runs(s, "docker run") or runs(s, "iso/builder") for s in steps(publish)), "the publish job never builds or runs the tree's builder")
iso = first_step(publish, lambda s: s.get("id") == "iso")
check(iso is not None and guard < iso < secret, "the publish job checks the ISO before any step that sees a secret")
for fragment, description in [
    ('[[ $found == "$name"$\'\\n\'"$name.sha256" ]] ||', "the artifact holds exactly the ISO and its checksum"),
    ('[[ -f $dir/$name && ! -L $dir/$name ]] ||', "the ISO is a plain file"),
    ('(cd "$dir" && sha256sum "$name" >"$name.sha256")', "the checksum is worked out again from the ISO"),
]:
    check(runs(steps(publish)[iso], fragment), f"the publish job checks that {description}", script(steps(publish)[iso]))
attest = first_step(publish, lambda s: uses(s, "actions/attest-build-provenance"))
check(attest is not None and iso < attest, "the publish job attests the ISO it checked")
check("id-token" not in (build.get("permissions") or {}), "only the publish job can mint an OIDC token")
ok("build-iso.yml publishes only from main, and checks the tag and the ISO before the Docker Hub token")

notify = workflows["notify-pkgs.yml"]
check(notify["on"] == {"push": {"branches": ["main"]}}, "notify-pkgs.yml only runs on pushes to main", str(notify["on"]))
check(notify.get("permissions") == {}, "notify-pkgs.yml asks for no GITHUB_TOKEN scopes")
check(set(notify["jobs"]) == {"dispatch"}, "notify-pkgs.yml has one job")
dispatch = notify["jobs"]["dispatch"]
check(environment(dispatch) == "maitri-pkgs", "the dispatch job is in the maitri-pkgs environment")
check(not any((s.get("uses") or "") for s in steps(dispatch)), "the dispatch job checks nothing out and runs no action")
ok("notify-pkgs.yml reaches the dispatch token only from main, without running anything from the tree")
EOF

/usr/bin/python3 -I "$test_tmp/guard.py" "$ROOT"
