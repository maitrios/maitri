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


def environment(job):
    value = job.get("environment")
    return value.get("name") if isinstance(value, dict) else value


def steps(job):
    return job.get("steps") or []


def first_step(job, predicate):
    return next((i for i, step in enumerate(steps(job)) if predicate(step)), None)


def runs(step, text):
    return text in (step.get("run") or "")


def uses(step, action):
    return (step.get("uses") or "").startswith(action + "@")


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
        check(str(job.get("if", "")).startswith(MAIN_GATE), f"{where} only runs on main")
        check(not sees_secret(job.get("env") or {}), f"{where} keeps its secrets in the steps that use them")
        for step in steps(job):
            check(not expressions(step.get("run") or ""), f"{where}: no expression is expanded inside a run script",
                  step.get("run"))
            check(not (uses(step, "actions/checkout") and "ref" in (step.get("with") or {})),
                  f"{where} only checks out main", yaml.safe_dump(step))
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
tree = first_step(build, lambda s: uses(s, "actions/checkout") and "ref" in (s.get("with") or {}))
docker = first_step(build, lambda s: runs(s, "docker run"))
check(None not in (tag_check, tree, docker) and tag_check < tree < docker,
      "the build job checks the tag before it checks out or builds the tag's tree")
check(steps(build)[tag_check].get("if") == "inputs.release_tag != ''" and runs(steps(build)[tag_check], 'refs/heads/main'),
      "a release build only starts on main")
ok("the build job runs the tree it builds with no environment, no secrets and a read-only token")

check(publish.get("needs") == "build", "the publish job runs after the build")
check(publish.get("if") == f"{MAIN_GATE} && inputs.release_tag != ''", "the publish job only runs for a release, on main", str(publish.get("if")))
check(environment(publish) == "docker-hub", "the publish job is the one in the docker-hub environment")
guard = first_step(publish, lambda s: runs(s, 'tools/check-release-tag.sh "$TAG"'))
secret = first_step(publish, sees_secret)
check(None not in (guard, secret) and guard < secret, "the publish job checks the tag before any step that sees a secret")
check(not any(runs(s, "docker run") or runs(s, "iso/builder") for s in steps(publish)), "the publish job never builds or runs the tree's builder")
check("needs.build" not in yaml.safe_dump(publish), "the publish job takes nothing from the build job but the artifact")
check(first_step(publish, lambda s: uses(s, "actions/attest-build-provenance")) is not None,
      "the publish job attests the ISO")
check("id-token" not in (build.get("permissions") or {}), "only the publish job can mint an OIDC token")
ok("build-iso.yml publishes only from main, and checks the tag before the Docker Hub token")

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
