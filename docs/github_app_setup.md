# Setting Up ACE GitHub App

This guide explains how to set up a GitHub App for ACE to enable automatic PR creation with optimized code, similar to CodeFlash.

## Why a GitHub App?

A GitHub App provides several advantages over personal access tokens:

1. **Fine-grained permissions**: Request only the permissions your app needs
2. **Rate limits per installation**: Each installation gets its own rate limit
3. **Better security**: No need to use personal credentials
4. **Installation-based**: Users can install the app on specific repositories

## Creating a GitHub App

1. Go to your GitHub account → Settings → Developer settings → GitHub Apps → New GitHub App

2. Fill in the app details:
   - **Name**: ACE Optimizer (or your preferred name)
   - **Description**: AI-powered code optimization tool that creates pull requests with optimized code
   - **Homepage URL**: For local development, you can use `http://localhost:4000`
   
3. Set the webhook details:
   - **Webhook URL**: For local development: `http://localhost:4000/webhooks/github` 
   - **Webhook secret**: Generate a secure random string and save it for later
   - You'll need to use a service like ngrok to expose your local server for webhook testing

4. Set the following permissions:
   - **Repository permissions**:
     - Contents: Read & write (to create branches and PRs)
     - Pull requests: Read & write (to create and comment on PRs)
     - Metadata: Read-only (required)
   
5. Set the following events:
   - Pull request
   - Push
   
6. Choose where the app can be installed:
   - **Only on this account**: Limits installation to your account only (good for testing)
   
7. Click "Create GitHub App"

## Generating a Private Key

After creating the app, you need to generate a private key:

1. On your app's settings page, scroll down to "Private keys"
2. Click "Generate a private key"
3. This will download a `.pem` file - save it in your project directory (e.g., `priv/github_app_key.pem`)

## Installing the App

1. On your app's settings page, go to the "Install App" tab
2. Choose the account and repositories where you want to install the app
3. Complete the installation
4. After installation, note your installation ID from the URL: `https://github.com/settings/installations/{INSTALLATION_ID}`

## Configuring ACE

Add GitHub App configuration in your development environment:

```elixir
# In config/dev.exs
config :ace, :github_app,
  app_id: "YOUR_APP_ID",  # Found on the app's settings page
  installation_id: "YOUR_INSTALLATION_ID",  # From the installation URL
  private_key_path: "priv/github_app_key.pem"  # Path to private key file

# Add webhook secret for GitHub App webhooks
config :ace, :github_webhook_secret, "your_webhook_secret_here"
```

## Setting Up for Local Testing

For local development and testing:

1. **Setup**:
   - Create a GitHub App as described above
   - Generate a private key and install the app
   - Configure the app in your ACE application

2. **Local testing**:
   - Set up ngrok or similar tool to expose your local server: `ngrok http 4000`
   - Update your GitHub App's webhook URL to the ngrok URL
   - Ensure your app ID, installation ID, and private key path are correct
   - Run ACE locally: `mix phx.server`

## Implementing the Create PR Feature

Once your GitHub App is configured, you'll need to implement the feature to create pull requests with optimization suggestions:

1. Update your LiveView to include a button that creates PRs with optimizations
2. Implement the server-side logic to:
   - Create a new branch based on the PR branch
   - Apply optimization suggestions to the code
   - Commit the changes
   - Create a new PR with the optimizations

## Troubleshooting

- **Authentication Errors**: Check your app ID, installation ID, and private key
- **Permission Errors**: Ensure your app has the correct permissions
- **Webhook Errors**: Verify the webhook URL and secret are correctly configured
- **Local Development**: Use ngrok to receive webhooks locally

## Adding Joken Dependency

Remember to add the Joken library to your dependencies in `mix.exs`:

```elixir
defp deps do
  [
    # ... existing deps ...
    {:joken, "~> 2.5"}
  ]
end
```

## Resources

- [GitHub Apps Documentation](https://docs.github.com/en/developers/apps/getting-started-with-apps/about-apps)
- [GitHub API Documentation](https://docs.github.com/en/rest) 