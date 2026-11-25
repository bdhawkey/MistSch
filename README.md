# MistSch

## Overview

Training project for setting up a vibe coding pipeline: code is written in Claude Code, pushed to GitHub, and deployed automatically to an AWS EC2 instance by GitHub Actions. The first deployed app is a browser Snake game.

## Files

| File | Purpose |
| --- | --- |
| `CLAUDE.md` | Instructions for Claude Code: style rules, code standards, and workflow. |
| `README.md` | Project documentation. Updated whenever code changes. |
| `site/index.html` | Snake game. Single static file, no dependencies. |
| `deploy/deploy.sh` | Runs on the EC2 instance: installs nginx if missing and publishes `site/`. |
| `.github/workflows/deploy.yml` | GitHub Actions workflow that deploys to EC2 on every push to `main`. |
| `Start` | Placeholder file. |

## Snake game

- Play: open `http://<EC2 public IP>/` in a browser (currently `http://16.171.200.209/`).
- Run locally: open `site/index.html` directly in a browser.
- Controls: arrow keys or WASD to move, Space to start or pause, swipe on touch screens.
- 20x20 grid, speed increases with each food eaten, best score saved in the browser.
- Efficiency: the snake is a ring buffer plus an occupancy grid, so each move and collision check is O(1), and only changed cells are redrawn each frame.

## Deployment pipeline

On every push to `main` (or a manual run from the Actions tab), the workflow:

1. Connects to the EC2 instance over SSH using the key stored in GitHub secrets.
2. Uploads `site/` and `deploy/` as one compressed stream.
3. Runs `deploy/deploy.sh`, which installs nginx if needed (supports Amazon Linux and Ubuntu), copies the site into the web root, and checks it is served locally.
4. Fetches the page from the internet to confirm it is reachable.

### One-time setup

1. In GitHub: Settings, Secrets and variables, Actions. Add these repository secrets:
   - `EC2_HOST`: the instance public IP, for example `16.171.200.209`.
   - `EC2_USER`: the SSH user, `ec2-user` (Amazon Linux) or `ubuntu` (Ubuntu).
   - `EC2_SSH_KEY`: the full contents of the instance `.pem` private key.
2. In the EC2 security group, allow inbound:
   - TCP 22 from GitHub Actions runners (for training, `0.0.0.0/0`; login is key-only).
   - TCP 80 from `0.0.0.0/0` so the game is reachable.

If the instance IP changes (for example after a stop and start without an Elastic IP), update the `EC2_HOST` secret.

## Workflow

Code is developed in Claude Code, committed, and pushed to GitHub. Merging to `main` deploys to EC2. The README is updated with every code change.

## Changelog

- Fixed deploy site checks failing with "curl: Failed writing body" (curl piped into `grep -q` under pipefail).
- Added Snake game (`site/index.html`), EC2 deploy script, and GitHub Actions deploy workflow.
- Added `CLAUDE.md` with project rules and workflow.
