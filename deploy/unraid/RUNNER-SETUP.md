# FamilyGuild deploy runner on Unraid

This sets up a GitHub Actions runner on Tower so a person, or an agent, can push FamilyGuild Lua scripts and SQL to the server with one button. You do this once.

The runner is registered on the **FamilyGuildAC** repository only. It runs as root and can control Docker. Deploys are manual, only `master` is allowed, and dry run is on by default.

**How files get to the server:** `/mnt/user/Rompecuori/FamilyGuild` is not a git checkout. The workflow checks out the repo into the runner's own work folder (`actions/checkout`), then copies `scripts/lua/familyguild/`, `sql/custom/` and the `build/` scripts into the Tower folder. Nothing runs `git pull` on the server. `.env`, `docker-compose*.yml` and `build/src/` are never touched.

## 1. Open the runner page and copy the one-hour token

1. Open https://github.com/thatoneguy1245/FamilyGuildAC/settings/actions/runners/new
2. Choose **Linux** and **x64**.

The page shows a `./config.sh` line with a real token in it. **Copy that real token.** It lasts one hour. Leave the page open until step 3 finishes. If it expires, reload the page and copy the new one.

Copy the page's `curl` line and `tar` line too. The `shasum` line is optional (Unraid may not have `shasum`).

> **Ignore the page's `mkdir actions-runner && cd actions-runner` line.** It would put the runner in root's home (`/root`), and on Unraid `/root` lives in RAM and is wiped at every reboot. Use the folder in step 2 instead.

## 2. Download the runner

On Tower, open the web Terminal. You are root.

```bash
mkdir -p /mnt/user/appdata/actions-runner-familyguild/actions-runner
cd /mnt/user/appdata/actions-runner-familyguild/actions-runner
```

Paste the `curl` line and the `tar` line from the GitHub page and run them here. Use the lines from the page; the version number changes.

## 3. Register it

Still in that folder:

```bash
export RUNNER_ALLOW_RUNASROOT=1
./config.sh --url https://github.com/thatoneguy1245/FamilyGuildAC --token PASTE_REAL_TOKEN_HERE --name familyguild-unraid --labels familyguild-deploy --work _work --unattended --replace
```

Replace `PASTE_REAL_TOKEN_HERE` with the token from the runner page. **Do not paste the literal `<token>` placeholder** from any guide, including GitHub's own page text; if your command contains `<token>` or `PASTE_REAL_TOKEN_HERE`, stop and copy the real token.

When it finishes, the Runners page lists `familyguild-unraid` (offline until step 4).

## 4. Start it when the array starts

Install **User Scripts** from Community Applications if needed. Add a new script, schedule **At Startup of Array**:

```bash
#!/bin/bash
cd /mnt/user/appdata/actions-runner-familyguild/actions-runner
export RUNNER_ALLOW_RUNASROOT=1
exec ./run.sh
```

Click **Run Script in Background** once now. Refresh the Runners page; it should say **Idle**. Don't start a second copy while one is running.

## 5. Token an agent uses to start a deploy

This is different from the one-hour runner token. It only lets an agent start the workflow and watch it.

1. Open https://github.com/settings/personal-access-tokens/new
2. Resource owner: `thatoneguy1245`.
3. Repository access: **Only select repositories** → `FamilyGuildAC`.
4. Repository permissions: **Actions → Read and write**. Leave everything else at no access.
5. Generate and copy it (GitHub shows it once). Never commit it or put it in the workflow.

```bash
GH_TOKEN=YOUR_FINE_GRAINED_TOKEN gh workflow run deploy-familyguild.yml --repo thatoneguy1245/FamilyGuildAC --ref master -f dry_run=true
GH_TOKEN=YOUR_FINE_GRAINED_TOKEN gh run watch --repo thatoneguy1245/FamilyGuildAC
```

Or without a token: repo → **Actions** → **Deploy FamilyGuild** → **Run workflow**, branch `master`.

## 6. First run is a dry run

The workflow file must be on `master` before GitHub shows the button. Run it with **dry run** checked (the default). The log should say the paths exist, show which files differ, and end with "Dry run. Nothing was changed."

## What a real deploy does

Uncheck **dry run**:

1. Checks out `master` into the runner's `_work` folder.
2. Copies `scripts/lua/familyguild/`, `sql/custom/` and `build/*.sh|*.yml` into `/mnt/user/Rompecuori/FamilyGuild`.
3. Only if **apply_sql** is checked: dumps all three databases to `backups/fg-<date>-predeploy.sql`, then applies `sql/custom/0*`–`8*` (05_quest_900004, 10_, 20_) to `acore_world` in order. `90_undo_upgrades.sql` is never run automatically. (These files delete-then-insert, so rerunning them is safe.)
4. `docker compose restart ac-worldserver`, waits for it to be running, and prints Lua/error log lines. If it doesn't come up, it prints the last 200 log lines and fails.

It never edits `.env` or compose files, never rebuilds images, and never deletes data. Rollback is the same as in UPGRADES-1-4.md.

Do not add a push trigger. The runner controls host Docker, so deploys stay manual and master-only.
