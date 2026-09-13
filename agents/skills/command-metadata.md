# Command Metadata

Read this before adding or changing commands in `bin/`.

Commands in `bin/` can declare CLI metadata in comments near the top of the
file. `bin/maitri` scans the first 80 lines, and tests expect command metadata
to remain valid.

Supported metadata keys:

- `# maitri:group=...` - override the command group inferred from the filename
- `# maitri:name=...` - override the command name inferred from the filename
- `# maitri:summary=...` - short help text
- `# maitri:args=...` - usage arguments
- `# maitri:examples=...` - examples separated with ` | `
- `# maitri:alias=...` / `# maitri:aliases=...` - alternate routes
- `# maitri:hidden=true` - hide from default command listings
- `# maitri:requires-sudo=true` - mark commands that require sudo

Only use `maitri:examples` where there are args that need explaining.

Prefer explicit metadata for user-facing commands. Keep routes consistent with
the filename unless there is a deliberate alias or compatibility route.

Example:

```bash
# maitri:summary=Take a screenshot
# maitri:args=[smart|region|windows|fullscreen] [slurp|copy]
# maitri:examples=maitri screenshot | maitri capture screenshot region
```
