# GitHub Webhook Setup for Automatic PR Optimization

This guide explains how to set up GitHub webhooks to automatically trigger code optimization on your pull requests, similar to how CodeFlash works.

## Overview

When configured correctly, the system will:
1. Automatically analyze new pull requests when they're created
2. Re-analyze pull requests when new commits are pushed
3. Generate optimization suggestions
4. Post those suggestions as comments on the PR

## Step 1: Generate a Webhook Secret

First, generate a secure webhook secret:

```bash
openssl rand -hex 20
```

Save this secret for the next steps.

## Step 2: Configure Your Application

Add the webhook secret to your application config:

```elixir
# config/config.exs or config/prod.secret.exs
config :ace, :github_webhook_secret, "your_generated_secret"
```

## Step 3: Configure the GitHub Webhook

1. Go to your GitHub repository
2. Click on "Settings" > "Webhooks" > "Add webhook"
3. Configure the webhook:
   - **Payload URL**: `https://your-server-url.com/webhooks/github`
   - **Content type**: `application/json`
   - **Secret**: Enter the secret you generated in Step 1
   - **SSL verification**: Enabled (recommended)
   - **Which events would you like to trigger this webhook?**: 
     - Select "Let me select individual events"
     - Check "Pull requests" and "Issue comments" (for comment-based triggers)
   - **Active**: Checked

4. Click "Add webhook"

## Step 4: Test the Webhook

After configuring the webhook, you can test it by:

1. Creating a new pull request in your repository
2. The webhook should trigger and your system will receive the event
3. Check the "Recent Deliveries" section of the webhook settings to verify the event was delivered successfully

## How It Works

1. When a PR is created, GitHub sends a `pull_request` event with `action: "opened"` to your webhook endpoint
2. Your application registers the PR and automatically triggers optimization
3. When the PR receives new commits, GitHub sends a `pull_request` event with `action: "synchronize"`
4. Your application re-analyzes the PR with the new code

## Debugging

You can use the provided scripts to simulate webhook events locally:

- `test_webhook_pr.exs` - Simulates a new PR creation
- `test_webhook_pr_sync.exs` - Simulates new commits being pushed to an existing PR

Run them with:

```bash
mix run test_webhook_pr.exs
mix run test_webhook_pr_sync.exs
```

## Troubleshooting

If the webhook isn't working:

1. Check the "Recent Deliveries" section in GitHub webhook settings
2. Verify your server is accessible from the internet
3. Check your application logs for any errors processing the webhook payload
4. Ensure the webhook secret matches between GitHub and your application 