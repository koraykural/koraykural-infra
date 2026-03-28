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

## DNS setup

At your domain registrar, add these records pointing to your VPS IP:

| Type | Name | Value |
|------|------|-------|
| `A` | `@` | `<VPS_IP>` |
| `A` | `www` | `<VPS_IP>` |
| `A` | `*` | `<VPS_IP>` |

The wildcard `*` record covers all subdomains automatically — no new DNS record needed per project.

## First-time VPS setup

The repo is private, so copy-paste the script manually:

```bash
ssh root@<VPS_IP>
nano bootstrap-vps.sh   # paste contents of scripts/bootstrap-vps.sh
bash bootstrap-vps.sh
```

## Adding a new project

**Static site:**
1. Copy `nginx/_template-static.conf` → `nginx/PROJECT_NAME.koraykural.com.conf`, replace `PROJECT_NAME`
2. Push — CI auto-reloads nginx
3. SSH into VPS and get a cert for the subdomain:
```bash
certbot certonly --nginx --non-interactive --agree-tos \
  --email koraykural99@gmail.com \
  -d PROJECT_NAME.koraykural.com
```
4. In the project repo, add `.github/workflows/deploy.yml`:

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
3. SSH into VPS and get a cert for the subdomain:
```bash
certbot certonly --nginx --non-interactive --agree-tos \
  --email koraykural99@gmail.com \
  -d PROJECT_NAME.koraykural.com
```
4. SSH into VPS, clone repo to `/var/www/PROJECT_NAME.koraykural.com`, run `pm2 start server.js --name PROJECT_NAME`
5. In the project repo, add `.github/workflows/deploy.yml`:

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
