// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
// Import Chart.js for dashboard charts
import Chart from "chart.js/auto"
// Import vis-network for relationship visualization
// (Note: You'd need to run `npm install vis-network --prefix assets` to add this dependency)
import { Network, DataSet } from "vis-network"

// Define hooks for LiveView
let Hooks = {}

// Code editor hook
Hooks.CodeEditor = {
  mounted() {
    // Set initial value from server
    if (this.el.value === "" && this.el.dataset.content) {
      this.el.value = this.el.dataset.content
    }
    
    // Listen for changes and push to server
    this.el.addEventListener("input", e => {
      this.pushEvent("content-changed", {content: e.target.value})
    });
  }
}

// Chart hooks
Hooks.PerformanceChart = {
  mounted() {
    this.renderChart()
    
    // Re-render when data changes
    this.handleEvent("chart-data-updated", () => {
      this.renderChart()
    })
  },
  
  renderChart() {
    // Parse chart data from data attribute
    const chartDataStr = this.el.getAttribute("data-chart")
    let chartData = {labels: [], values: []}
    
    try {
      if (chartDataStr) {
        const data = JSON.parse(chartDataStr)
        chartData.labels = data.dates || []
        chartData.values = data.improvements || []
      }
    } catch (e) {
      console.error("Error parsing chart data:", e)
    }
    
    // Destroy existing chart if it exists
    if (this.chart) {
      this.chart.destroy()
    }
    
    // Create new chart
    this.chart = new Chart(this.el.getContext('2d'), {
      type: 'line',
      data: {
        labels: chartData.labels,
        datasets: [{
          label: 'Performance Improvement',
          data: chartData.values,
          backgroundColor: 'rgba(54, 162, 235, 0.2)',
          borderColor: 'rgba(54, 162, 235, 1)',
          borderWidth: 1,
          tension: 0.1
        }]
      },
      options: {
        responsive: true,
        scales: {
          y: {
            beginAtZero: false,
            title: {
              display: true,
              text: 'Improvement %'
            }
          },
          x: {
            title: {
              display: true,
              text: 'Date'
            }
          }
        }
      }
    })
  }
}

Hooks.LanguageChart = {
  mounted() {
    this.renderChart()
    
    // Re-render when data changes
    this.handleEvent("chart-data-updated", () => {
      this.renderChart()
    })
  },
  
  renderChart() {
    // Parse chart data from data attribute
    const chartDataStr = this.el.getAttribute("data-chart")
    let chartData = {labels: [], values: []}
    
    try {
      if (chartDataStr) {
        const data = JSON.parse(chartDataStr)
        chartData.labels = data.languages || []
        chartData.values = data.counts || []
      }
    } catch (e) {
      console.error("Error parsing chart data:", e)
    }
    
    // Destroy existing chart if it exists
    if (this.chart) {
      this.chart.destroy()
    }
    
    // Color palette for languages
    const colors = {
      'elixir': 'rgba(163, 88, 251, 0.8)',
      'javascript': 'rgba(255, 206, 86, 0.8)',
      'python': 'rgba(54, 162, 235, 0.8)',
      'ruby': 'rgba(255, 99, 132, 0.8)',
      'go': 'rgba(75, 192, 192, 0.8)',
      'unknown': 'rgba(201, 203, 207, 0.8)'
    }
    
    // Map labels to colors
    const backgroundColors = chartData.labels.map(label => 
      colors[label.toLowerCase()] || colors.unknown
    )
    
    // Create new chart
    this.chart = new Chart(this.el.getContext('2d'), {
      type: 'pie',
      data: {
        labels: chartData.labels,
        datasets: [{
          data: chartData.values,
          backgroundColor: backgroundColors,
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            position: 'right',
          }
        }
      }
    })
  }
}

Hooks.TypeChart = {
  mounted() {
    this.renderChart()
    
    // Re-render when data changes
    this.handleEvent("chart-data-updated", () => {
      this.renderChart()
    })
  },
  
  renderChart() {
    // Parse chart data from data attribute
    const chartDataStr = this.el.getAttribute("data-chart")
    let chartData = {labels: [], values: []}
    
    try {
      if (chartDataStr) {
        const data = JSON.parse(chartDataStr)
        chartData.labels = data.types || []
        chartData.values = data.counts || []
      }
    } catch (e) {
      console.error("Error parsing chart data:", e)
    }
    
    // Destroy existing chart if it exists
    if (this.chart) {
      this.chart.destroy()
    }
    
    // Color palette for opportunity types
    const colors = {
      'performance': 'rgba(255, 99, 132, 0.8)',
      'maintainability': 'rgba(54, 162, 235, 0.8)',
      'security': 'rgba(255, 206, 86, 0.8)',
      'reliability': 'rgba(75, 192, 192, 0.8)',
      'unknown': 'rgba(201, 203, 207, 0.8)'
    }
    
    // Map labels to colors
    const backgroundColors = chartData.labels.map(label => 
      colors[label.toLowerCase()] || colors.unknown
    )
    
    // Create new chart
    this.chart = new Chart(this.el.getContext('2d'), {
      type: 'doughnut',
      data: {
        labels: chartData.labels,
        datasets: [{
          data: chartData.values,
          backgroundColor: backgroundColors,
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            position: 'right',
          }
        }
      }
    })
  }
}

Hooks.SeverityChart = {
  mounted() {
    this.renderChart()
    
    // Re-render when data changes
    this.handleEvent("chart-data-updated", () => {
      this.renderChart()
    })
  },
  
  renderChart() {
    // Parse chart data from data attribute
    const chartDataStr = this.el.getAttribute("data-chart")
    let chartData = {labels: [], values: []}
    
    try {
      if (chartDataStr) {
        const data = JSON.parse(chartDataStr)
        chartData.labels = data.severities || []
        chartData.values = data.counts || []
      }
    } catch (e) {
      console.error("Error parsing chart data:", e)
    }
    
    // Destroy existing chart if it exists
    if (this.chart) {
      this.chart.destroy()
    }
    
    // Color palette for severity levels
    const colors = {
      'high': 'rgba(255, 99, 132, 0.8)',
      'medium': 'rgba(255, 206, 86, 0.8)',
      'low': 'rgba(75, 192, 192, 0.8)',
      'unknown': 'rgba(201, 203, 207, 0.8)'
    }
    
    // Map labels to colors
    const backgroundColors = chartData.labels.map(label => 
      colors[label.toLowerCase()] || colors.unknown
    )
    
    // Create new chart
    this.chart = new Chart(this.el.getContext('2d'), {
      type: 'bar',
      data: {
        labels: chartData.labels,
        datasets: [{
          label: 'Count',
          data: chartData.values,
          backgroundColor: backgroundColors,
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        scales: {
          y: {
            beginAtZero: true,
            title: {
              display: true,
              text: 'Count'
            }
          }
        }
      }
    })
  }
}

// Relationship graph visualization hook
Hooks.RelationshipGraph = {
  mounted() {
    this.renderGraph()
    
    // Re-render when data changes
    this.handleEvent("graph-data-updated", () => {
      this.renderGraph()
    })
  },
  
  renderGraph() {
    // Parse graph data from data attribute
    const graphDataStr = this.el.getAttribute("data-graph")
    let graphData = {nodes: [], edges: []}
    
    try {
      if (graphDataStr) {
        graphData = JSON.parse(graphDataStr)
      }
    } catch (e) {
      console.error("Error parsing graph data:", e)
      return
    }
    
    // If we don't have any data, show a message
    if (graphData.nodes.length === 0) {
      this.showEmptyMessage()
      return
    }
    
    // Prepare data for vis-network
    const nodes = new DataSet(graphData.nodes.map(node => ({
      id: node.id,
      label: node.label,
      title: node.title,
      group: node.group
    })))
    
    const edges = new DataSet(graphData.edges.map(edge => ({
      id: edge.id,
      from: edge.from,
      to: edge.to,
      label: edge.label,
      arrows: edge.arrows,
      title: edge.label
    })))
    
    // Destroy existing network if it exists
    if (this.network) {
      this.network.destroy()
      this.el.innerHTML = ''
    }
    
    // Define colors for language groups
    const groups = {
      'elixir': {
        color: {
          background: 'rgba(163, 88, 251, 0.8)',
          border: 'rgba(163, 88, 251, 1)',
          highlight: {
            background: 'rgba(163, 88, 251, 1)',
            border: 'rgba(163, 88, 251, 1)'
          }
        }
      },
      'javascript': {
        color: {
          background: 'rgba(255, 206, 86, 0.8)',
          border: 'rgba(255, 206, 86, 1)',
          highlight: {
            background: 'rgba(255, 206, 86, 1)',
            border: 'rgba(255, 206, 86, 1)'
          }
        }
      },
      'python': {
        color: {
          background: 'rgba(54, 162, 235, 0.8)',
          border: 'rgba(54, 162, 235, 1)',
          highlight: {
            background: 'rgba(54, 162, 235, 1)',
            border: 'rgba(54, 162, 235, 1)'
          }
        }
      },
      'ruby': {
        color: {
          background: 'rgba(255, 99, 132, 0.8)',
          border: 'rgba(255, 99, 132, 1)',
          highlight: {
            background: 'rgba(255, 99, 132, 1)',
            border: 'rgba(255, 99, 132, 1)'
          }
        }
      },
      'go': {
        color: {
          background: 'rgba(75, 192, 192, 0.8)',
          border: 'rgba(75, 192, 192, 1)',
          highlight: {
            background: 'rgba(75, 192, 192, 1)',
            border: 'rgba(75, 192, 192, 1)'
          }
        }
      },
      'unknown': {
        color: {
          background: 'rgba(201, 203, 207, 0.8)',
          border: 'rgba(201, 203, 207, 1)',
          highlight: {
            background: 'rgba(201, 203, 207, 1)',
            border: 'rgba(201, 203, 207, 1)'
          }
        }
      }
    }
    
    // Define colors for different relationship types
    const edgeColors = {
      'imports': '#f39c12',
      'extends': '#e74c3c',
      'implements': '#2ecc71',
      'uses': '#3498db',
      'references': '#9b59b6',
      'depends_on': '#7f8c8d'
    }
    
    // Apply edge colors based on relationship type
    edges.forEach(edge => {
      const color = edgeColors[edge.label] || '#7f8c8d'
      edge.color = {
        color: color,
        highlight: color,
        hover: color
      }
    })
    
    // Create the network
    const container = this.el
    const data = {nodes, edges}
    const options = {
      nodes: {
        shape: 'dot',
        size: 16,
        font: {
          size: 12,
          face: 'Tahoma'
        },
        borderWidth: 2,
        shadow: true
      },
      edges: {
        width: 2,
        shadow: true,
        font: {
          size: 12,
          align: 'middle'
        },
        length: 200
      },
      physics: {
        enabled: true,
        barnesHut: {
          gravitationalConstant: -2000,
          centralGravity: 0.5,
          springLength: 140,
          springConstant: 0.04,
          damping: 0.09
        }
      },
      groups: groups,
      interaction: {
        navigationButtons: true,
        keyboard: true,
        tooltipDelay: 300,
        hover: true
      },
      layout: {
        improvedLayout: true,
        hierarchical: {
          enabled: false
        }
      }
    }
    
    // Create network
    this.network = new Network(container, data, options)
    
    // Handle node click to show details
    this.network.on('click', (params) => {
      if (params.nodes.length > 0) {
        const nodeId = params.nodes[0]
        this.pushEvent('select-file-node', {id: nodeId})
      }
    })
    
    // Check if we need to highlight a selected node
    const selectedNode = this.el.getAttribute('data-selected-node')
    if (selectedNode) {
      this.network.selectNodes([parseInt(selectedNode)])
      this.network.focus(parseInt(selectedNode), {
        scale: 1.2,
        animation: true
      })
    }
  },
  
  showEmptyMessage() {
    this.el.innerHTML = `
      <div class="empty-graph-message">
        <p>No file relationships available. Run a multi-file analysis first.</p>
      </div>
    `
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

