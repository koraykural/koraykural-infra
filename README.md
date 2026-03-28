# koraykural-infra

Server configuration for koraykural.com.

## Structure

```
nginx/                    nginx site configs (symlinked to /etc/nginx/sites-*)
  koraykural.com.conf     main domain
  _template-static.conf   copy for new static subdomain projects
  _template-backend.conf  copy for new backend subdomain projects
scripts/
  bootstrap-vps.sh        run once on a fresh VPS
  apply-nginx.sh          pull & reload nginx (called by CI)
.github/workflows/
  apply-nginx.yml         auto-applies nginx changes on push
  deploy-static.yml       reusable workflow for static sites
  deploy-backend.yml      reusable workflow for backend apps
```

## First-time VPS setup

```bash
ssh root@<VPS_IP>
bash <(curl -s https://raw.githubusercontent.com/koraykural/koraykural-infra/main/scripts/bootstrap-vps.sh)
```

## Adding a new project

**Static site:**
1. Copy `nginx/_template-static.conf` → `nginx/PROJECT_NAME.koraykural.com.conf`, replace `PROJECT_NAME`
2. Push — CI auto-reloads nginx
3. In the project repo, add `.github/workflows/deploy.yml`:

```yaml
on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: koraykural/koraykural-infra/.github/workflows/deploy-static.yml@main
    with:
      subdomain: PROJECT_NAME
      build_command: npm run build
      dist_dir: dist
    secrets:
      VPS_HOST: ${{ secrets.VPS_HOST }}
      VPS_SSH_KEY: ${{ secrets.VPS_SSH_KEY }}
```

**Backend app:**
1. Copy `nginx/_template-backend.conf` → `nginx/PROJECT_NAME.koraykural.com.conf`, replace `PROJECT_NAME` and `PORT`
2. Push — CI auto-reloads nginx
3. SSH into VPS, clone repo to `/var/www/PROJECT_NAME.koraykural.com`, run `pm2 start server.js --name PROJECT_NAME`
4. In the project repo, add `.github/workflows/deploy.yml`:

```yaml
on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: koraykural/koraykural-infra/.github/workflows/deploy-backend.yml@main
    with:
      subdomain: PROJECT_NAME
      pm2_name: PROJECT_NAME
    secrets:
      VPS_HOST: ${{ secrets.VPS_HOST }}
      VPS_SSH_KEY: ${{ secrets.VPS_SSH_KEY }}
```

## GitHub Secrets

Set these in each project repo (Settings → Secrets → Actions):

| Secret | Value |
|--------|-------|
| `VPS_HOST` | Your VPS IP address |
| `VPS_SSH_KEY` | Private SSH key of the `deploy` user |
