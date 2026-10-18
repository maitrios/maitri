#!/bin/bash

# A lint for honest mistakes in the workflows that hold secrets, not a sandbox.
# The real protection is the main-only environments plus CODEOWNERS review of
# workflow changes (k7lab/maitrios#53). It catches the slips listed below, and
# exotic evasions beyond them are out of scope by design.

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

ASSIGNMENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*\+?=")
LEADERS = {"!", "{", "if", "then", "else", "elif", "while", "until", "do"}
SKIPPED = {"for", "select", "case", "function", "}", "fi", "done", "esac", "[[", "(("}
WRAPPERS = {"sudo", "env", "exec", "command", "nohup", "xargs", "timeout", "nice", "time"}
INTERPRETERS = {"bash", "sh", "dash", "zsh", "ksh", "source", ".", "python", "python3", "node", "perl", "ruby", "pwsh"}
GIT_MOVES = {"checkout", "switch", "restore", "worktree", "pull", "reset", "merge", "clone"}
TOOLS = re.compile(r"(?:^|=|^-[A-Za-z])(?:\./|\$\{?GITHUB_WORKSPACE\}?/)?tools(?:/|$)")

root = sys.argv[1]
workflows_dir = os.path.join(root, ".github", "workflows")


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


def strings(value):
    if isinstance(value, dict):
        for key, item in value.items():
            yield from strings(key)
            yield from strings(item)
    elif isinstance(value, list):
        for item in value:
            yield from strings(item)
    elif isinstance(value, str):
        yield value


def expressions(value):
    return [e for text in strings(value) for e in re.findall(r"\$\{\{(.*?)\}\}", text, re.S)]


def sees_secret(value):
    for expression in expressions(value):
        rest = re.sub(r"\bsecrets\s*\.\s*github_token\b", "", expression, flags=re.I)
        if re.search(r"\bsecrets\b", rest, re.I):
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


def lower_keys(mapping):
    return {str(key).lower(): value for key, value in (mapping or {}).items()}


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
    return str(step.get("uses") or "").lower().startswith(action + "@")


def closing(text, start):
    depth, i = 0, start
    while i < len(text):
        c = text[i]
        if c == "\\":
            i += 2
            continue
        if c in "'\"":
            end = text.find(c, i + 1)
            i = len(text) if end < 0 else end + 1
            continue
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return len(text)


def substitutions(text):
    found, i = [], 0
    while i < len(text):
        if text.startswith("$(", i) and not text.startswith("$((", i):
            end = closing(text, i + 1)
            found.append(text[i + 2:end])
            i = end + 1
        elif text[i] == "`":
            end = text.find("`", i + 1)
            end = len(text) if end < 0 else end
            found.append(text[i + 1:end])
            i = end + 1
        else:
            i += 1
    return found


def shell_commands(text):
    """The simple commands in a script, each as (words, redirect targets).

    Words lose their quotes, comments and heredoc bodies are skipped, and the
    scripts inside $( ), backticks and <( ) are read as commands of their own."""
    commands, words, redirects, heredocs = [], [], [], []
    state = {"word": None, "target": False}
    i, n = 0, len(text)

    def add(part):
        state["word"] = (state["word"] or "") + part

    def end_word():
        word, target = state["word"], state["target"]
        if word is None:
            return
        if target == "heredoc":
            heredocs.append(word)
        elif target:
            redirects.append(word)
        else:
            words.append(word)
        state.update(word=None, target=False)

    def end_command():
        nonlocal words, redirects
        end_word()
        if words or redirects:
            commands.append((words, redirects))
        words, redirects = [], []

    def nested(inner):
        for part in inner:
            commands.extend(shell_commands(part))

    while i < n:
        c = text[i]
        at_word_start = state["word"] is None
        if c == "\\":
            if not text.startswith("\\\n", i):
                add(text[i + 1:i + 2])
            i += 2
        elif c == "'":
            end = text.find("'", i + 1)
            end = n if end < 0 else end
            add(text[i + 1:end])
            i = end + 1
        elif c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                if text[j] == "\\":
                    j += 2
                elif text.startswith("$(", j) and not text.startswith("$((", j):
                    j = closing(text, j + 1) + 1
                elif text[j] == "`":
                    end = text.find("`", j + 1)
                    j = n if end < 0 else end + 1
                else:
                    j += 1
            quoted = text[i + 1:j]
            nested(substitutions(quoted))
            add(quoted)
            i = j + 1
        elif c == "`" or (c in "$<>" and text.startswith("(", i + 1) and not text.startswith("((", i + 1)):
            start = i + (1 if c == "`" else 2)
            end = text.find("`", start) if c == "`" else closing(text, i + 1)
            end = n if end < 0 else end
            nested([text[start:end]])
            add(text[i:end + 1])
            i = end + 1
        elif text.startswith("$((", i) or (at_word_start and text.startswith("((", i)):
            end = closing(text, i + (1 if c == "$" else 0))
            nested(substitutions(text[i:end + 1]))
            add(text[i:end + 1] if c == "$" else "((")
            i = end + 1
        elif at_word_start and re.match(r"\[\[\s", text[i:]):
            match = re.compile(r"\s\]\](?=\s|[;&|)]|$)").search(text, i)
            end = n if match is None else match.end()
            nested(substitutions(text[i:end]))
            add("[[")
            i = end
        elif c == "$" and text.startswith("${", i):
            end = text.find("}", i)
            end = n if end < 0 else end
            add(text[i:end + 1])
            i = end + 1
        elif c == "#" and at_word_start:
            end = text.find("\n", i)
            i = n if end < 0 else end
        elif c == "\n":
            end_command()
            i += 1
            for delimiter in heredocs:
                while i < n:
                    end = text.find("\n", i)
                    line = text[i:n if end < 0 else end]
                    i = n if end < 0 else end + 1
                    if line.lstrip("\t") == delimiter:
                        break
            heredocs.clear()
        elif c in " \t":
            end_word()
            i += 1
        elif c in "<>" or text.startswith("&>", i):
            if state["word"] is not None and state["word"].isdigit() and not state["target"]:
                state["word"] = None
            else:
                end_word()
            operator = re.match(r"&>>?|<<<|<<-?|<>|>>|>\||>&|<&|>|<", text[i:]).group(0)
            state["target"] = "heredoc" if operator in ("<<", "<<-") else True
            i += len(operator)
        elif c in ";&|()":
            end_command()
            i += 1
        else:
            add(c)
            i += 1
    end_command()
    return commands


def safe_tool(word):
    return re.fullmatch(r"tools/[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)*", word) is not None and ".." not in word.split("/")


def shell_problem(text):
    for words, redirects in shell_commands(text):
        everything = words + redirects
        for word in everything:
            if re.match(r"(?:PATH|BASH_ENV)\+?=", word):
                return f"sets {word.split('=')[0]}: {words}"
            if re.search(r"GITHUB_(?:PATH|ENV)\b", word):
                return f"writes to $GITHUB_PATH or $GITHUB_ENV: {everything}"
        for target in redirects:
            if TOOLS.search(target):
                return f"writes into tools/: {target}"
        i = 0
        while i < len(words) and (words[i] in LEADERS or ASSIGNMENT.match(words[i])):
            i += 1
        if i == len(words) or words[i] in SKIPPED:
            continue
        while i < len(words) and words[i] in WRAPPERS:
            wrapper = words[i]
            i += 1
            while i < len(words) and (words[i].startswith("-") or (wrapper == "env" and ASSIGNMENT.match(words[i]))):
                i += 1
            if wrapper == "timeout" and i < len(words):
                i += 1
        if i == len(words):
            continue
        command, args = words[i], words[i + 1:]
        if command == "eval":
            return f"runs eval: {words}"
        if command in ("cd", "pushd", "popd"):
            return f"changes directory away from main's checkout: {words}"
        if command in INTERPRETERS:
            if any(re.fullmatch(r"-[A-Za-z]*c[A-Za-z]*", a) for a in args if not a.startswith("--")):
                return f"runs {command} -c: {words}"
            target = next((a for a in args if not a.startswith("-")), None)
            if target is None or not safe_tool(target):
                return f"runs {command} on something other than main's tools/: {words}"
            args = [a for a in args if a is not target]
        elif command == "git":
            j = 0
            while j < len(args) and args[j].startswith("-"):
                j += 2 if args[j] in ("-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path") else 1
            if j < len(args) and args[j] in GIT_MOVES:
                return f"moves or replaces its checkout: {words}"
        elif command == "gh" and args[:2] in (["pr", "checkout"], ["repo", "clone"]):
            return f"checks out other code: {words}"
        elif not (safe_tool(command) or re.fullmatch(r"[A-Za-z0-9_+:\[\]-][A-Za-z0-9_.+:\[\]-]*", command)):
            return f"runs a file it didn't check out from main: {words}"
        for arg in args:
            if TOOLS.search(arg):
                return f"writes into tools/, or names it for something other than running it: {words}"
    return None


def defaults_shell(scope):
    return (((scope or {}).get("defaults") or {}).get("run") or {})


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
        for scope in (workflow, job):
            run_defaults = defaults_shell(scope)
            check(run_defaults.get("shell", "bash") == "bash" and "working-directory" not in run_defaults,
                  f"{where} runs its scripts with bash, from main's checkout", str(run_defaults))
        for scope in (workflow.get("env"), job.get("env")):
            check(not {"PATH", "BASH_ENV"} & set(scope or {}), f"{where} leaves PATH and BASH_ENV alone")
        for step in steps(job):
            detail = yaml.safe_dump(step)
            check(not expressions(step.get("run") or ""), f"{where}: no expression is expanded inside a run script", detail)
            check(step.get("shell", "bash") == "bash" and "working-directory" not in step,
                  f"{where} runs its scripts with bash, from main's checkout", detail)
            check(not {"PATH", "BASH_ENV"} & set(step.get("env") or {}), f"{where} leaves PATH and BASH_ENV alone", detail)
            action = step.get("uses")
            check(action is None or re.fullmatch(r"[A-Za-z0-9-]+/[A-Za-z0-9._/-]+@[0-9a-f]{40}", str(action)),
                  f"{where} only uses actions pinned to a commit, never a local one", detail)
            inputs = lower_keys(step.get("with"))
            if uses(step, "actions/checkout"):
                check(not {"ref", "repository"} & set(inputs), f"{where} only checks out main", detail)
            if uses(step, "actions/download-artifact"):
                path = str(inputs.get("path", ""))
                check(not {"run-id", "repository", "github-token"} & set(inputs), f"{where} only downloads this run's artifacts", detail)
                check(path.startswith("${{ runner.temp }}/") and ".." not in path, f"{where} downloads artifacts outside the checkout", detail)
            problem = shell_problem(script(step))
            check(problem is None, f"{where} only runs main's code from main's checkout", problem)
ok("every secret lives in a job that runs only on main, in a main-only environment, and runs only main's code")

for name, workflow in workflows.items():
    for job_name, job in (workflow.get("jobs") or {}).items():
        for step in steps(job):
            injected = [e for e in expressions(step.get("run") or "") if re.search(r"\binputs\b", e, re.I)]
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
trees = [i for i, s in enumerate(steps(build)) if uses(s, "actions/checkout") and "ref" in lower_keys(s.get("with"))]
releases = [i for i in trees if steps(build)[i].get("if") == "inputs.release_tag != ''"]
check(len(releases) == 1 and lower_keys(steps(build)[releases[0]]["with"])["ref"] == "${{ steps.tag.outputs.commit }}",
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
stable = first_step(build, lambda s: s.get("id") == "stable")
check(stable is not None and stable < docker and runs(steps(build)[stable], 'echo "version=$have" >>"$GITHUB_OUTPUT"'),
      "a release build records the maitri version the stable channel carries before it builds")
docker_step = steps(build)[docker]
check((docker_step.get("env") or {}).get("MAITRI_EXPECT_VERSION") == "${{ steps.stable.outputs.version }}"
      and runs(docker_step, "-e MAITRI_EXPECT_VERSION "),
      "the builder is held to that version")
name_step = first_step(build, lambda s: runs(s, 'mv -f release/runtime.version "release/$NAME.version"'))
check(name_step is not None and docker < name_step and (steps(build)[name_step].get("env") or {}).get("MAITRI_EXPECT_VERSION") == "${{ steps.stable.outputs.version }}"
      and runs(steps(build)[name_step], '$(<"release/$NAME.version") == "maitri $MAITRI_EXPECT_VERSION" ]] ||'),
      "a release build refuses an ISO whose recorded maitri version isn't the one it started with")
upload = first_step(build, lambda s: uses(s, "actions/upload-artifact"))
check(upload is not None and name_step < upload and lower_keys(steps(build)[upload]["with"]).get("overwrite") is True
      and "release/*.version" in str(lower_keys(steps(build)[upload]["with"]).get("path")),
      "the ISO, its checksum and its version are uploaded, and a full re-run replaces them")
with open(os.path.join(root, "iso", "builder", "build-iso.sh")) as f:
    builder = f.read()
assemble = builder.find("\nmkarchiso ")
check(re.search(r'check_runtime_version\(\) \{\n  \[\[ -z \$\{MAITRI_EXPECT_VERSION:-\} \|\| \$1 == "\$MAITRI_EXPECT_VERSION" \]\] && return\n.*\n  exit 1\n\}', builder) is not None,
      "the builder stops when maitri isn't the version it was given")
for marker in ('check_runtime_version "$bootstrap_version"', 'check_runtime_version "${runtime_versions[0]}"',
               '"${runtime_versions[0]}" >/out/runtime.version'):
    check(0 <= builder.find(marker) < assemble, f"the builder runs {marker} before it assembles the ISO")
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
check(sum(text.count("needs.build") for text in strings(publish)) == 1, "the publish job takes nothing else from the build job but the artifact")
check(not any(runs(s, "docker run") or runs(s, "iso/builder") for s in steps(publish)), "the publish job never builds or runs the tree's builder")
iso = first_step(publish, lambda s: s.get("id") == "iso")
check(iso is not None and guard < iso < secret, "the publish job checks the ISO before any step that sees a secret")
for fragment, description in [
    ('[[ $found == "$name"$\'\\n\'"$name.sha256"$\'\\n\'"$name.version" ]] ||', "the artifact holds exactly the ISO, its checksum and its version"),
    ('[[ -f $dir/$name && ! -L $dir/$name ]] ||', "the ISO is a plain file"),
    ('sha256sum "$name" >"$name.sha256"', "the checksum is worked out again from the ISO"),
    ('${BASH_REMATCH[1]} == "${TAG#v}" ]] ||', "the ISO bundles maitri at the tag's version"),
]:
    check(runs(steps(publish)[iso], fragment), f"the publish job checks that {description}", script(steps(publish)[iso]))
publish_step = steps(publish)[secret]
check((publish_step.get("env") or {}).get("MAITRI_VERSION") == "${{ steps.iso.outputs.maitri }}"
      and runs(publish_step, '--annotation "io.maitri.package.version=$MAITRI_VERSION"'),
      "the publish job shows the maitri version the ISO bundles")
attest = first_step(publish, lambda s: uses(s, "actions/attest-build-provenance"))
check(attest is not None and iso < attest, "the publish job attests the ISO it checked")
check("id-token" not in (build.get("permissions") or {}), "only the publish job can mint an OIDC token")
ok("build-iso.yml publishes only from main, and checks the tag, the ISO and its maitri before the Docker Hub token")

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
