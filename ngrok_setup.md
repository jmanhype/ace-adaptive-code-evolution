# Setting Up ngrok for Webhook Testing

To receive GitHub webhooks on your local machine:

1. Install ngrok from [https://ngrok.com/download](https://ngrok.com/download)

2. Start your Phoenix server:
   ```
   ./dev_server.sh
   ```

3. In a separate terminal, start ngrok to expose port 4000:
   ```
   ngrok http 4000
   ```

4. Ngrok will provide a public URL (e.g., https://abc123.ngrok.io)

5. Update your GitHub App webhook URL:
   - Go to your GitHub App settings
   - Change the webhook URL to: https://YOUR_NGROK_URL/webhooks/github
   - Save changes

6. With this setup, GitHub webhook events will be forwarded to your local machine.

7. When you're done testing, you can stop ngrok and update your GitHub App webhook URL back to your production URL. 