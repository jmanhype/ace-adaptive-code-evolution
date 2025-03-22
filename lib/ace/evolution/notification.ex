defmodule Ace.Evolution.Notification do
  @moduledoc """
  Handles notifications for evolution proposals and other important events.
  Supports multiple notification channels like Slack, email, etc.
  """
  require Logger
  alias Ace.Core.EvolutionProposal
  
  @doc """
  Sends a notification to all configured channels.
  
  ## Parameters
    
    - `message`: Message structure to send
  """
  def notify_team(message) do
    channels = Application.get_env(:ace, :notification_channels, ["slack"])
    
    Enum.each(channels, fn channel ->
      notify_channel(channel, message)
    end)
  end
  
  @doc """
  Notifies the team about a new proposal that requires review.
  
  ## Parameters
    
    - `proposal_id`: ID of the proposal
  """
  def notify_about_proposal(proposal_id) do
    proposal = EvolutionProposal.get_proposal(proposal_id)
    
    if is_nil(proposal) do
      Logger.warning("Cannot notify about non-existent proposal: #{proposal_id}")
      {:error, :not_found}
    else
      message = %{
        type: :new_proposal,
        proposal_id: proposal_id,
        dsl_name: proposal.dsl_name,
        timestamp: DateTime.utc_now(),
        review_url: generate_review_url(proposal_id)
      }
      
      notify_team(message)
      {:ok, :notified}
    end
  end
  
  @doc """
  Notifies the team about a new pull request created by the system.
  
  ## Parameters
    
    - `pr_url`: URL of the pull request
  """
  def notify_about_pr(pr_url) do
    message = %{
      type: :pull_request,
      pr_url: pr_url,
      timestamp: DateTime.utc_now()
    }
    
    notify_team(message)
    {:ok, :notified}
  end
  
  # Private helpers
  
  defp notify_channel("slack", message) do
    # Format message for Slack
    formatted_message = format_slack_message(message)
    
    # Send to Slack webhook
    webhook_url = Application.get_env(:ace, :slack_webhook_url)
    if webhook_url && webhook_url != "" do
      case HTTPoison.post(webhook_url, Jason.encode!(formatted_message), [
        {"Content-Type", "application/json"}
      ]) do
        {:ok, response} ->
          Logger.debug("Slack notification sent successfully: #{inspect(response.status_code)}")
        {:error, error} ->
          Logger.error("Failed to send Slack notification: #{inspect(error)}")
      end
    else
      Logger.debug("No Slack webhook configured, skipping notification")
    end
  end
  
  defp notify_channel("email", message) do
    # Format message for email
    {subject, body} = format_email_message(message)
    
    # Get recipients
    recipients = Application.get_env(:ace, :notification_emails, [])
    
    # Send email if available
    # This is a placeholder - actual implementation depends on email service
    if Enum.any?(recipients) do
      Logger.debug("Would send email to #{inspect(recipients)}")
      Logger.debug("Subject: #{subject}")
      Logger.debug("Body: #{body}")
    else
      Logger.debug("No email recipients configured, skipping notification")
    end
  end
  
  defp format_slack_message(%{type: :new_proposal} = message) do
    %{
      text: "New AI-generated code proposal requires review",
      blocks: [
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: ":robot_face: *New AI-generated code proposal requires review*"
          }
        },
        %{
          type: "section",
          fields: [
            %{
              type: "mrkdwn",
              text: "*Module:*\n#{message.dsl_name}"
            },
            %{
              type: "mrkdwn", 
              text: "*Time:*\n#{format_datetime(message.timestamp)}"
            }
          ]
        },
        %{
          type: "actions",
          elements: [
            %{
              type: "button",
              text: %{
                type: "plain_text",
                text: "Review Proposal"
              },
              url: message.review_url,
              style: "primary"
            }
          ]
        }
      ]
    }
  end
  
  defp format_slack_message(%{type: :pull_request} = message) do
    %{
      text: "New AI-generated Pull Request",
      blocks: [
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: ":robot_face: *New AI-generated Pull Request*"
          }
        },
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: "An AI-generated improvement has been created as a Pull Request. Please review and merge if appropriate."
          }
        },
        %{
          type: "actions",
          elements: [
            %{
              type: "button",
              text: %{
                type: "plain_text",
                text: "Review PR"
              },
              url: message.pr_url,
              style: "primary"
            }
          ]
        }
      ]
    }
  end
  
  defp format_email_message(%{type: :new_proposal} = message) do
    subject = "AI-generated code proposal requires review"
    
    body = """
    A new AI-generated code proposal requires review.
    
    Module: #{message.dsl_name}
    Time: #{format_datetime(message.timestamp)}
    
    Review URL: #{message.review_url}
    """
    
    {subject, body}
  end
  
  defp format_email_message(%{type: :pull_request} = message) do
    subject = "New AI-generated Pull Request"
    
    body = """
    A new AI-generated Pull Request has been created and requires review.
    
    PR URL: #{message.pr_url}
    Time: #{format_datetime(message.timestamp)}
    
    Please review and merge if the changes are appropriate.
    """
    
    {subject, body}
  end
  
  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p")
  end
  
  defp generate_review_url(proposal_id) do
    base_url = Application.get_env(:ace, :base_url, "http://localhost:4000")
    "#{base_url}/admin/evolution/proposals/#{proposal_id}"
  end
end