# GitHub Integration Guide

This guide explains how to set up ACE's GitHub integration for automatic code optimization on every pull request, similar to how CodeFlash.ai works.

## Automatic PR Optimization

ACE automatically analyzes every pull request to identify performance issues and optimization opportunities. The workflow is:

1. A pull request is created or updated in your GitHub repository
2. ACE analyzes the code changes to find optimization opportunities
3. Results appear as a status check and comment on your PR
4. You can view detailed results and apply the suggested optimizations

## Setup Instructions

### 1. Configure the GitHub Action

The GitHub Action is the easiest way to integrate ACE with your repository. It runs automatically on every pull request.

1. **Create repository secrets**

   In your GitHub repository, go to Settings > Secrets and variables > Actions and add:
   
   - `ACE_API_TOKEN`: Your ACE API token
   - `ACE_API_URL`: URL to your ACE instance (e.g., `https://your-ace-instance.com`)

2. **Add the workflow file**

   The GitHub Actions workflow is already set up in your repository at `.github/workflows/pr-optimize.yml`.
   
   This workflow:
   - Runs on every new PR and PR update
   - Registers the PR with ACE
   - Adds a status check to your PR
   - Displays optimization results as a PR comment

3. **Test the integration**

   Create a pull request to verify the integration. You should see:
   - A "ACE Code Optimization" status check on your PR
   - A comment with optimization suggestions when the analysis completes

### 2. Webhook Integration (Optional)

For more advanced integration, set up a webhook to process GitHub events directly:

1. **Generate a webhook secret**

   ```bash
   openssl rand -hex 20
   ```

2. **Configure ACE with the secret**

   ```elixir
   # In config/config.exs
   config :ace, :github_webhook_secret, "your_webhook_secret_here"
   ```

   Or as an environment variable:
   ```bash
   export GITHUB_WEBHOOK_SECRET="your_webhook_secret_here"
   ```

3. **Set up the GitHub webhook**

   In your repository Settings > Webhooks > Add webhook:
   - Payload URL: `https://your-ace-instance.com/webhooks/github`
   - Content type: `application/json`
   - Secret: Your generated webhook secret
   - Events: Pull requests, Pull request review comments

## Understanding Results

### Status Checks

ACE adds a status check to each pull request:

- **Pending**: Analysis is in progress
- **Success**: Analysis completed (with or without suggestions)
- **Error**: Something went wrong during analysis

The status description indicates the number of optimization opportunities found.

### PR Comments

After analysis completes, ACE adds a comment to your PR with:

1. A summary of the optimization opportunities found
2. The top 5 most important suggestions, sorted by severity
3. A link to the full report in the ACE dashboard

Severity indicators help you prioritize:
- 🔴 High severity: Critical issues that should be fixed
- 🟠 Medium severity: Important optimizations to consider
- 🔵 Low severity: Minor improvements

### ACE Dashboard

Click the "View full report" link to open the ACE dashboard, where you can:

1. See all optimization suggestions in detail
2. View the original and optimized code side-by-side
3. Apply optimizations with one click
4. Track optimization history and improvements

## Troubleshooting

### GitHub Action Issues

If the GitHub Action isn't working:
- Check that your ACE_API_TOKEN and ACE_API_URL secrets are set correctly
- Look at the Action run logs for error messages
- Verify your ACE instance is accessible from GitHub's servers

### Webhook Issues

If webhooks aren't processing:
- Verify your webhook secret matches in both GitHub and ACE
- Check GitHub's webhook delivery logs (in repository settings)
- Ensure your ACE instance is publicly accessible

### API Access Issues

If you get authentication errors:
- Regenerate your ACE API token
- Check that you're using the correct authorization format in requests
- Verify your token has the necessary permissions 