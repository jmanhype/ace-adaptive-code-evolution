# ACE LiveView Interface

The ACE web interface is built using Phoenix LiveView, providing a real-time, interactive dashboard for managing code optimizations. This document explains how to use, customize, and extend the LiveView interface.

## Overview

The LiveView interface consists of the following main components:

1. **Dashboard overview**: Shows summary metrics and recent activities
2. **Project management**: Create and manage multi-file projects
3. **File analysis**: Analyze individual files and view opportunities
4. **Optimization management**: Generate and review optimizations
5. **Evaluation results**: View and compare optimizations
6. **File relationships**: Visualize dependencies and relationships between files

## Key Components

### DashboardLive Module

The main LiveView module (`AceWeb.DashboardLive`) handles all user interactions and real-time updates. It subscribes to several PubSub topics to receive updates from the backend services:

```elixir
Phoenix.PubSub.subscribe(Ace.PubSub, "ace:dashboard")
Phoenix.PubSub.subscribe(Ace.PubSub, "ace:analyses")
Phoenix.PubSub.subscribe(Ace.PubSub, "ace:optimizations")
Phoenix.PubSub.subscribe(Ace.PubSub, "ace:evaluations")
Phoenix.PubSub.subscribe(Ace.PubSub, "ace:projects")
Phoenix.PubSub.subscribe(Ace.PubSub, "ace:relationships")
Phoenix.PubSub.subscribe(Ace.PubSub, "ace:errors")
```

### Template Structure

The main template (`dashboard_live/index.html.heex`) is organized into sections:

1. **Header**: Shows the dashboard title, API status indicator, and primary actions
2. **Metrics cards**: Display summary statistics for analyses, opportunities, and optimizations
3. **Recent activities**: Show a timeline of recent actions
4. **Content area**: Contains tab-specific content based on the active tab

### State Management

The LiveView maintains state through assigns:

- `:api_status`: Current API provider status and configuration
- `:active_tab`: Currently selected tab (overview, projects, files, etc.)
- `:analyses`, `:opportunities`, `:optimizations`, `:evaluations`: Lists of data
- `:projects`: List of available projects
- `:metrics`: System-wide metrics
- Various UI state flags like `:loading`, `:analyzing`, etc.

### Event Handling

User interactions are handled through `handle_event/3` callbacks, while backend updates are received through `handle_info/2` callbacks.

## Customizing the Interface

### Changing the Layout

To change the overall layout, modify the `index.html.heex` template. The template uses Phoenix HTML components like `.header`, `.card`, etc., which can be customized in your project's `core_components.ex` file.

### Adding New Tabs

To add a new tab to the dashboard:

1. Update the `apply_action/3` function in `dashboard_live.ex` to handle the new tab:

```elixir
defp apply_action(socket, :new_tab, _params) do
  socket
  |> assign(:active_tab, :new_tab)
end
```

2. Add a new route in `router.ex`:

```elixir
live "/dashboard/new-tab", DashboardLive, :new_tab
```

3. Add the tab link to the template:

```html
<.link patch={~p"/dashboard/new-tab"} class={tab_class(:new_tab, @active_tab)}>
  New Tab
</.link>
```

4. Add the tab content to `index.html.heex`:

```html
<div :if={@active_tab == :new_tab} class="mt-6">
  <h2 class="text-lg font-medium text-gray-900">New Tab Content</h2>
  <!-- Tab content here -->
</div>
```

### Customizing Charts

The dashboard includes ChartJS-based visualizations. To customize charts:

1. Update the `generate_chart_data/0` function in `dashboard_live.ex` to include your data
2. Update the JavaScript event handlers to process your data
3. Add new chart containers to the template

### Adding New Event Handlers

To handle new user interactions:

1. Add a new `handle_event/3` function:

```elixir
@impl true
def handle_event("your-event", params, socket) do
  # Process the event
  {:noreply, socket}
end
```

2. Add the event trigger to the template:

```html
<button phx-click="your-event" phx-value-id={item.id}>
  Action
</button>
```

## API Integration

The dashboard automatically detects available API providers and displays their status. To add support for a new AI provider:

1. Update the `check_api_availability/0` function in `dashboard_live.ex`
2. Add the provider to the environment variable detection in the template
3. Update the API error handling in `handle_info/2` callbacks

## Extending with Custom Components

To create a custom component for the dashboard:

1. Create a new LiveComponent module:

```elixir
defmodule AceWeb.Components.CustomComponent do
  use AceWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <!-- Component content -->
    </div>
    """
  end

  # Component callbacks here
end
```

2. Add the component to the template:

```html
<.live_component
  module={AceWeb.Components.CustomComponent}
  id="custom-component"
  some_data={@some_data}
/>
```

## Best Practices

1. **Performance**: Large data sets should be paginated to avoid slowdowns
2. **Error Handling**: All API calls should have proper error handling
3. **Real-time Updates**: Use PubSub for real-time updates rather than polling
4. **State Management**: Keep related state in maps/structs for easier management
5. **Accessibility**: Ensure all UI elements have proper ARIA attributes and are keyboard accessible

## Troubleshooting

Common issues and solutions:

1. **LiveView disconnects**: Check for large state updates that might exceed the maximum socket payload size
2. **Slow rendering**: Identify and optimize template sections that might be rendering too much data
3. **API errors**: Check environment variables and network connectivity to API providers
4. **UI inconsistencies**: Verify that all UI state updates are properly handled in event callbacks