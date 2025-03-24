# Setting Up GitHub App with Cloudflare Tunnel

## 1. Create a GitHub App

1. Go to your GitHub account → Settings → Developer settings → GitHub Apps → New GitHub App

2. Fill in the app details:
   - **Name**: ACE Optimizer (or your preferred name)
   - **Description**: AI-powered code optimization tool
   - **Homepage URL**: https://ace-github-app.quickcolbert.com

3. Set the webhook details:
   - **Webhook URL**: https://ace-github-app.quickcolbert.com/webhooks/github
   - **Webhook secret**: Generate a random string (you'll need this later)

4. Set the required permissions:
   - **Repository permissions**:
     - Contents: Read & write (for creating branches and PRs)
     - Pull requests: Read & write
     - Metadata: Read-only

5. Subscribe to events:
   - Pull request
   - Push

6. Choose "Only on this account" for installation scope

7. Click "Create GitHub App"

## 2. Generate a Private Key

1. On your app's settings page, scroll to "Private keys"
2. Click "Generate a private key"
3. This will download a `.pem` file - save it in your project directory at `priv/github_app_key.pem`

## 3. Install the App

1. Go to the "Install App" tab on your GitHub App settings
2. Choose repositories to install it on
3. After installation, note your installation ID from the URL: `https://github.com/settings/installations/{INSTALLATION_ID}`

## 4. Configure ACE

1. Fill in the actual values in your `.env` file:
   ```
   # GitHub App Configuration
   GITHUB_APP_ID="your-app-id"
   GITHUB_APP_INSTALLATION_ID="your-installation-id" 
   GITHUB_APP_PRIVATE_KEY_PATH="priv/github_app_key.pem"
   GITHUB_WEBHOOK_SECRET="your-webhook-secret-here"
   ```

2. Make sure your private key is at `priv/github_app_key.pem`

## 5. Set Up Cloudflare Tunnel

1. Start your Phoenix server:
   ```
   ./dev_server.sh
   ```

2. In a separate terminal, start the Cloudflare tunnel:
   ```
   cloudflared tunnel run ace-github-app
   ```

3. Your local server is now accessible at `https://ace-github-app.quickcolbert.com`

## 6. Test the Setup

1. Trigger a GitHub event (like opening a PR) in one of the repositories where you installed the app

2. Check the logs in both your Phoenix server and Cloudflare tunnel terminal to see the incoming webhooks

3. Verify that ACE is processing the events correctly

## 7. Troubleshooting

- If webhooks aren't being received, check that your tunnel is running and that the GitHub App webhook URL is correctly set
- Verify that your environment variables are loaded correctly
- Check the GitHub App settings to ensure the webhook URL and secret are correct
- Look at the webhook deliveries in GitHub App settings to see if there are any errors

## 8. Going to Production

For production deployment:
1. Set up a proper domain and SSL certificate
2. Configure your environment variables in your production environment
3. Use a more permanent solution for the tunnel, like Cloudflare for Teams 