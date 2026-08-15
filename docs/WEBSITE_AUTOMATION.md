# GymFeed website automation

The production website is built from the Flutter application and deployed to
Namecheap whenever `main` receives a relevant change. The workflow lives at
`.github/workflows/deploy-website.yml`.

## Deployment flow

1. GitHub checks out the repository.
2. Flutter `3.27.4` is installed and the test suite runs.
3. `flutter build web --release` creates the production application.
4. The deployment package receives the maintained `.htaccess`, App Links,
   public post handler, legal pages and supporting assets.
5. GitHub synchronizes the release to Namecheap over SSH on port `21098`.
6. The workflow checks the live home page, privacy page and Android App Links
   file before reporting success.

## Namecheap setup

1. In cPanel, open **Exclusive for Namecheap Customers → Manage Shell** and
   enable SSH.
2. In **Security → SSH Access → Manage SSH Keys**, import a dedicated public
   deployment key and authorize it. Do not reuse a personal SSH key.
3. In cPanel's **General Information → Server Information**, copy the full
   server hostname, such as `server123.web-hosting.com`.
4. From a trusted terminal, record the server host key after checking its
   fingerprint against the first successful cPanel/SSH connection:

   ```bash
   ssh-keyscan -p 21098 server123.web-hosting.com
   ```

## Required GitHub repository secrets

The workflow uses a GitHub environment named `production`. Add these encrypted
repository secrets so the deployment job can read them:

- `NAMECHEAP_SSH_HOST`: the full Namecheap server hostname.
- `NAMECHEAP_SSH_USER`: the cPanel username.
- `NAMECHEAP_SSH_PRIVATE_KEY`: the complete dedicated private key, including
  its BEGIN/END lines.
- `NAMECHEAP_SSH_KNOWN_HOSTS`: the verified `ssh-keyscan` output.
- `NAMECHEAP_DEPLOY_PATH`: `/home/CPANEL_USER/public_html`.

The workflow deliberately rejects any deployment path that does not end in the
current cPanel user's `public_html` directory. It also preserves `cgi-bin` and
Namecheap's ACME certificate-validation directory.

## GitHub repository

The existing application repository is sufficient; a second repository is not
required. The local `origin` must point to a repository that exists and that the
GitHub account can access. After the remote and secrets are configured, pushing
to `main` automatically updates `https://gymfeed.io`.
