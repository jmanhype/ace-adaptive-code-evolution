# ACE Codebase Mermaid Diagrams

This document contains various Mermaid diagrams visualizing the structure and relationships within the ACE codebase, generated from our code maps.

## Table of Contents

1. [System Architecture Diagrams](#system-architecture-diagrams)
   - [Core Module Structure](#core-module-structure)
   - [Web Application Structure](#web-application-structure)
2. [API Routes Diagram](#api-routes-diagram)
3. [Core Module Dependencies](#core-module-dependencies)
4. [GitHub Integration Flow](#github-integration-flow)
5. [Code Evolution Process](#code-evolution-process)
6. [Optimization Process Flow](#optimization-process-flow)
7. [Component Hierarchy](#component-hierarchy)
8. [File Complexity Heat Map](#file-complexity-heat-map)
9. [Language Optimization Support](#language-optimization-support)
10. [GitHub Integration Architecture](#github-integration-architecture)
11. [Evolution Process Timeline](#evolution-process-timeline)
12. [Technical Debt Map](#technical-debt-map)
13. [AI Orchestration Flow](#ai-orchestration-flow)
14. [Database Schema Relationships](#database-schema-relationships)
15. [Test Coverage Map](#test-coverage-map)
16. [Development Workflow](#development-workflow)
17. [File Modification Frequency](#file-modification-frequency)

## System Architecture Diagrams

### Core Module Structure

```mermaid
graph TD
    ACE[Ace]
    ACE --> Analysis[Ace.Analysis]
    ACE --> Evaluation[Ace.Evaluation]
    ACE --> Optimization[Ace.Optimization]
    ACE --> Core[Ace.Core]
    ACE --> Evolution[Ace.Evolution]
    ACE --> GitHub[Ace.GitHub]
    ACE --> Infrastructure[Ace.Infrastructure]
    ACE --> GraphQL[Ace.GraphQL]
    
    Infrastructure --> AI[Ace.Infrastructure.AI]
    Infrastructure --> Persistence[Ace.Infrastructure.Persistence]
    
    AI --> Orchestrator[AI.Orchestrator]
    AI --> CodeOptimizer[AI.CodeOptimizer]
    AI --> OpportunityWrapper[AI.OpportunityWrapper]
    AI --> Providers[AI.Providers]
    
    Providers --> Groq[AI.Providers.Groq]
    
    Core --> Models[Core.Models]
    Core --> Schemas[Core.Schemas]
    Models --> EvolutionProposal[Core.EvolutionProposal]
    
    GitHub --> GitHubModels[GitHub.Models]
    GitHub --> GitHubAPI[GitHub.GitHubAPI]
    GitHub --> Service[GitHub.Service]
    GitHub --> PRCreator[GitHub.PRCreator]
    GitHub --> AppAuth[GitHub.AppAuth]
    GitHub --> OptimizationAdapter[GitHub.OptimizationAdapter]
    
    GitHubModels --> PullRequest[GitHub.Models.PullRequest]
    GitHubModels --> PRFile[GitHub.Models.PRFile]
    GitHubModels --> OptimizationSuggestion[GitHub.Models.OptimizationSuggestion]
    
    Optimization --> Languages[Optimization.Languages]
    Languages --> Elixir[Languages.Elixir]
    Languages --> Python[Languages.Python]
    Languages --> JavaScript[Languages.JavaScript]
    Languages --> Ruby[Languages.Ruby]
    Languages --> Go[Languages.Go]
    
    GraphQL --> Resolvers[GraphQL.Resolvers]
    GraphQL --> Types[GraphQL.Types]
    GraphQL --> Schema[GraphQL.Schema]
    
    Evolution --> Service[Evolution.Service]
    Evolution --> Scheduler[Evolution.Scheduler]
    Evolution --> Notification[Evolution.Notification]
    
    classDef core fill:#f9f,stroke:#333,stroke-width:2px;
    classDef infrastructure fill:#bbf,stroke:#333,stroke-width:1px;
    classDef github fill:#bfb,stroke:#333,stroke-width:1px;
    
    class ACE,Core core;
    class Infrastructure,AI,Persistence infrastructure;
    class GitHub,GitHubModels,GitHubAPI github;
```

### Web Application Structure

```mermaid
graph TD
    AceWeb[AceWeb]
    AceWeb --> Controllers[AceWeb.Controllers]
    AceWeb --> Views[AceWeb.Views]
    AceWeb --> Templates[AceWeb.Templates]
    AceWeb --> Components[AceWeb.Components]
    AceWeb --> Channels[AceWeb.Channels]
    AceWeb --> Live[AceWeb.Live]
    AceWeb --> Router[AceWeb.Router]
    AceWeb --> Plugs[AceWeb.Plugs]
    
    Controllers --> EvolutionController[EvolutionController]
    Controllers --> WebhookController[WebhookController]
    Controllers --> GitHubAPIController[GitHubAPIController]
    Controllers --> PRController[PRController]
    
    Live --> DashboardLive[DashboardLive]
    Live --> GitHubLive[GitHubLive]
    
    GitHubLive --> PullRequests[GitHubLive.PullRequests]
    GitHubLive --> ShowPullRequest[GitHubLive.ShowPullRequest]
    
    Components --> Layouts[Components.Layouts]
    Components --> CoreComponents[Components.CoreComponents]
    
    Plugs --> RawBodyPlug[RawBodyPlug]
    
    classDef controllers fill:#f9f,stroke:#333,stroke-width:1px;
    classDef live fill:#bbf,stroke:#333,stroke-width:1px;
    
    class Controllers,EvolutionController,WebhookController,GitHubAPIController controllers;
    class Live,DashboardLive,GitHubLive live;
```

## API Routes Diagram

```mermaid
graph LR
    Browser[Browser Client]
    API[API Client]
    GitHub[GitHub Webhook]
    
    Browser --> BrowserRoutes["/browser routes"]
    API --> APIRoutes["/api routes"]
    GitHub --> WebhookRoutes["/webhooks routes"]
    
    subgraph BrowserRoutes
        direction TB
        BR_HOME["/"]
        BR_PROJECTS["/projects"]
        BR_FILES["/files"]
        BR_OPPORTUNITIES["/opportunities"]
        BR_OPTIMIZATIONS["/optimizations"]
        BR_EVALUATIONS["/evaluations"]
        BR_EVOLUTION["/evolution"]
        BR_EVOLUTION_PROPOSALS["/evolution/proposals"]
        BR_GITHUB_PRS["/github/pull_requests"]
        BR_GITHUB_PR["/github/pull_requests/:id"]
        BR_OPTIMIZE_PR["/optimize/:pr_id"]
    end
    
    subgraph APIRoutes
        direction TB
        API_PULL_REQUESTS["/api/pull_requests"]
        API_ANALYSES_OPTIMIZE["/api/analyses/:id/optimize"]
        API_GITHUB_PULL_REQUESTS["/api/github/pull_requests"]
        API_GITHUB_PR["/api/github/pull_requests/:id"]
        API_GITHUB_PR_OPTIMIZE["/api/github/pull_requests/:id/optimize"]
        API_GITHUB_PR_CREATE_OPTIMIZATION["/api/github/pull_requests/:id/create_optimization_pr"]
        API_GITHUB_PR_SUGGESTIONS["/api/github/pull_requests/:pr_id/suggestions"]
        API_GITHUB_PR_UI["/api/github/pull_requests/:pr_id/ui"]
        API_GITHUB_BRANCHES["/api/github/branches/:repo_name"]
        API_GITHUB_OPTIMIZE["/api/github/optimize"]
        API_GRAPHQL["/api/graphql"]
        API_GRAPHIQL["/api/graphiql"]
    end
    
    subgraph WebhookRoutes
        direction TB
        WH_GITHUB["/webhooks/github"]
    end
    
    classDef browser fill:#bbf,stroke:#333,stroke-width:1px;
    classDef api fill:#bfb,stroke:#333,stroke-width:1px;
    classDef webhook fill:#fbf,stroke:#333,stroke-width:1px;
    
    class BrowserRoutes,BR_HOME,BR_PROJECTS,BR_FILES,BR_OPPORTUNITIES,BR_OPTIMIZATIONS,BR_EVALUATIONS,BR_EVOLUTION,BR_EVOLUTION_PROPOSALS,BR_GITHUB_PRS,BR_GITHUB_PR,BR_OPTIMIZE_PR browser;
    class APIRoutes,API_PULL_REQUESTS,API_ANALYSES_OPTIMIZE,API_GITHUB_PULL_REQUESTS,API_GITHUB_PR,API_GITHUB_PR_OPTIMIZE,API_GITHUB_PR_CREATE_OPTIMIZATION,API_GITHUB_PR_SUGGESTIONS,API_GITHUB_PR_UI,API_GITHUB_BRANCHES,API_GITHUB_OPTIMIZE,API_GRAPHQL,API_GRAPHIQL api;
    class WebhookRoutes,WH_GITHUB webhook;
```

## Core Module Dependencies

```mermaid
flowchart TD
    ACE[Ace] --> Analysis
    ACE --> Evaluation
    ACE --> Optimization
    
    Analysis --> Core_Analysis[Core.Analysis]
    Analysis --> Core_Opportunity[Core.Opportunity]
    Analysis --> AI_Orchestrator[AI.Orchestrator]
    
    Evaluation --> Core_Evaluation[Core.Evaluation]
    Evaluation --> Core_Experiment[Core.Experiment]
    Evaluation --> AI_Orchestrator
    
    Evolution --> Core_EvolutionProposal[Core.EvolutionProposal]
    Evolution --> Evolution_Notification[Evolution.Notification]
    Evolution --> AI_Orchestrator
    
    GitHub --> AppAuth
    GitHub --> Models_PullRequest[Models.PullRequest]
    GitHub --> Models_PRFile[Models.PRFile]
    GitHub --> Models_OptimizationSuggestion[Models.OptimizationSuggestion]
    GitHub --> Service_Analysis[Analysis.Service]
    GitHub --> Service_Evolution[Evolution.Service]
    
    Optimization --> Core_Optimization[Core.Optimization]
    Optimization --> Core_Opportunity
    Optimization --> AI_Orchestrator
    
    AI_Orchestrator --> OpportunityWrapper
    
    GitHub_OptimizationAdapter[GitHub.OptimizationAdapter] --> CodeOptimizer[AI.CodeOptimizer]
    GitHub_OptimizationAdapter --> Service_Evolution
    GitHub_OptimizationAdapter --> Service_Optimization[Optimization.Service]
    
    classDef core fill:#f9f,stroke:#333,stroke-width:1px;
    classDef ai fill:#bbf,stroke:#333,stroke-width:1px;
    classDef github fill:#bfb,stroke:#333,stroke-width:1px;
    
    class ACE core;
    class AI_Orchestrator,OpportunityWrapper,CodeOptimizer ai;
    class GitHub,AppAuth,Models_PullRequest,Models_PRFile,Models_OptimizationSuggestion,GitHub_OptimizationAdapter github;
```

## GitHub Integration Flow

```mermaid
sequenceDiagram
    participant GitHub
    participant Webhook as AceWeb.WebhookController
    participant GitHubAPI as Ace.GitHub.GitHubAPI
    participant Service as Ace.GitHub.Service
    participant Optimizer as Ace.GitHub.OptimizationAdapter
    participant AIEngine as Ace.Infrastructure.AI.CodeOptimizer
    
    GitHub->>Webhook: Pull Request Event
    Webhook->>Service: Process Webhook
    Service->>GitHubAPI: Fetch PR Details
    GitHubAPI->>GitHub: API Request
    GitHub->>GitHubAPI: PR Data, Files
    
    Service->>Service: Create PR Record
    
    Note over Service,Optimizer: When optimization requested
    
    Service->>Optimizer: Optimize Pull Request
    Optimizer->>GitHubAPI: Fetch PR Files
    GitHubAPI->>GitHub: Get Files
    GitHub->>GitHubAPI: Files Content
    
    Optimizer->>AIEngine: Analyze Code
    AIEngine->>Optimizer: Optimization Suggestions
    
    Optimizer->>Service: Store Suggestions
    Service->>GitHubAPI: Post Comment with Suggestions
    GitHubAPI->>GitHub: Create Comment
    
    Note over Service,GitHub: When creating optimization PR
    
    Service->>GitHubAPI: Create Branch
    GitHubAPI->>GitHub: Create Branch
    Service->>GitHubAPI: Push Changes
    GitHubAPI->>GitHub: Push Changes
    Service->>GitHubAPI: Create PR
    GitHubAPI->>GitHub: Create PR
```

## Code Evolution Process

```mermaid
stateDiagram-v2
    [*] --> ProposalCreated
    ProposalCreated --> ProposalReviewed: Manual Review
    ProposalCreated --> ProposalScheduled: Auto Schedule
    
    ProposalScheduled --> ProposalPending: Ready to Apply
    ProposalReviewed --> ProposalApproved: Approve
    ProposalReviewed --> ProposalRejected: Reject
    
    ProposalApproved --> ProposalPending: Ready to Apply
    ProposalPending --> ProposalProcessing: Start Processing
    
    ProposalProcessing --> ProposalApplied: Success
    ProposalProcessing --> ProposalFailed: Error
    
    ProposalApplied --> ProposalDeployed: Deploy
    ProposalDeployed --> [*]
    
    ProposalRejected --> [*]
    ProposalFailed --> ProposalReviewed: Retry
```

## Optimization Process Flow

```mermaid
graph TD
    Start([Start]) --> DetectCode[Detect Code Files]
    DetectCode --> FilterLanguages[Filter Supported Languages]
    FilterLanguages --> AnalyzeCode[Analyze Code]
    
    AnalyzeCode --> Python[Python Analysis]
    AnalyzeCode --> JavaScript[JavaScript Analysis]
    AnalyzeCode --> Elixir[Elixir Analysis]
    AnalyzeCode --> Ruby[Ruby Analysis]
    AnalyzeCode --> Go[Go Analysis]
    
    Python --> IdentifyOpportunities[Identify Opportunities]
    JavaScript --> IdentifyOpportunities
    Elixir --> IdentifyOpportunities
    Ruby --> IdentifyOpportunities
    Go --> IdentifyOpportunities
    
    IdentifyOpportunities --> GenerateOptimizations[Generate Optimizations]
    GenerateOptimizations --> CreateSuggestions[Create Suggestions]
    CreateSuggestions --> FormatComments[Format Comments]
    FormatComments --> PostToGitHub[Post to GitHub]
    PostToGitHub --> End([End])
    
    classDef start fill:#bbf,stroke:#333,stroke-width:2px;
    classDef process fill:#bfb,stroke:#333,stroke-width:1px;
    classDef languages fill:#fbf,stroke:#333,stroke-width:1px;
    classDef end fill:#fbb,stroke:#333,stroke-width:2px;
    
    class Start start;
    class DetectCode,FilterLanguages,AnalyzeCode,IdentifyOpportunities,GenerateOptimizations,CreateSuggestions,FormatComments,PostToGitHub process;
    class Python,JavaScript,Elixir,Ruby,Go languages;
    class End end;
```

## Component Hierarchy

```mermaid
graph TD
    Root[Root Layout] --> App[App Layout]
    App --> Dashboard[Dashboard Live]
    App --> GitHubPR[GitHub PR Live]
    
    Dashboard --> Projects[Projects View]
    Dashboard --> Files[Files View]
    Dashboard --> Opportunities[Opportunities View]
    Dashboard --> Optimizations[Optimizations View]
    Dashboard --> Evaluations[Evaluations View]
    Dashboard --> Evolution[Evolution View]
    Dashboard --> Proposals[Evolution Proposals]
    
    GitHubPR --> PRList[PR List View]
    GitHubPR --> PRDetail[PR Detail View]
    
    PRDetail --> SuggestionList[Suggestion List]
    PRDetail --> FileViewer[File Viewer]
    PRDetail --> DiffViewer[Diff Viewer]
    PRDetail --> OptimizationActions[Optimization Actions]
    
    classDef layout fill:#f9f,stroke:#333,stroke-width:2px;
    classDef live fill:#bbf,stroke:#333,stroke-width:1px;
    classDef view fill:#bfb,stroke:#333,stroke-width:1px;
    classDef component fill:#fbf,stroke:#333,stroke-width:1px;
    
    class Root,App layout;
    class Dashboard,GitHubPR live;
    class Projects,Files,Opportunities,Optimizations,Evaluations,Evolution,Proposals,PRList,PRDetail view;
    class SuggestionList,FileViewer,DiffViewer,OptimizationActions component;
```

## File Complexity Heat Map

```mermaid
pie
    title "Top Code Complexity by Module"
    "GitHub Service" : 33
    "Infrastructure Orchestrator" : 18
    "GitHub API" : 15
    "GitHub API Controller" : 10
    "CLI" : 9
    "Optimization Adapter" : 8
    "Evolution Service" : 7
    "Config" : 6
    "Other Files" : 4
```

## Language Optimization Support

```mermaid
graph LR
    Ace[ACE Optimizer] --> Languages[Supported Languages]
    
    Languages --> Python[Python]
    Languages --> JavaScript[JavaScript]
    Languages --> Elixir[Elixir]
    Languages --> Ruby[Ruby]
    Languages --> Go[Go]
    
    Python --> PyFeatures[Features]
    JavaScript --> JSFeatures[Features]
    Elixir --> ExFeatures[Features]
    
    PyFeatures --> PyAlgorithmic[Algorithmic Improvement]
    PyFeatures --> PyMemory[Memory Optimization]
    PyFeatures --> PyStructural[Structural Refactoring]
    
    JSFeatures --> JSPerformance[Performance Optimization]
    JSFeatures --> JSMemory[Memory Management]
    JSFeatures --> JSModern[Modern JS Features]
    
    ExFeatures --> ExConcurrency[Concurrency Patterns]
    ExFeatures --> ExMemory[Memory Reduction]
    ExFeatures --> ExFunctional[Functional Patterns]
    
    classDef language fill:#bbf,stroke:#333,stroke-width:1px;
    classDef feature fill:#bfb,stroke:#333,stroke-width:1px;
    
    class Python,JavaScript,Elixir,Ruby,Go language;
    class PyAlgorithmic,PyMemory,PyStructural,JSPerformance,JSMemory,JSModern,ExConcurrency,ExMemory,ExFunctional feature;
```

## GitHub Integration Architecture

```mermaid
graph TD
    subgraph ACE[ACE Application]
        GitHub[GitHub Integration]
        Optimizer[Code Optimizer]
        DB[(Database)]
        
        GitHub --> DB
        GitHub --> Optimizer
        Optimizer --> DB
    end
    
    subgraph WebHooks[GitHub Events]
        PREvent[PR Created/Updated]
        CommentEvent[Comment Created]
        ReviewEvent[Review Submitted]
    end
    
    subgraph GitHubAPI[GitHub API]
        GetPR[Get PR Details]
        GetFiles[Get PR Files]
        CreateComment[Create Comment]
        CreatePR[Create PR]
    end
    
    WebHooks --> GitHub
    GitHub --> GitHubAPI
    
    classDef ace fill:#bbf,stroke:#333,stroke-width:1px;
    classDef github fill:#bfb,stroke:#333,stroke-width:1px;
    classDef api fill:#fbf,stroke:#333,stroke-width:1px;
    
    class ACE,GitHub,Optimizer,DB ace;
    class WebHooks,PREvent,CommentEvent,ReviewEvent github;
    class GitHubAPI,GetPR,GetFiles,CreateComment,CreatePR api;
```

## Evolution Process Timeline

```mermaid
gantt
    title Code Evolution Process Timeline
    dateFormat  YYYY-MM-DD
    
    section Proposal
    Create Proposal           :a1, 2025-03-01, 2d
    Review Proposal           :a2, after a1, 1d
    
    section Implementation
    Generate Code             :b1, after a2, 2d
    Test Code                 :b2, after b1, 2d
    
    section Deployment
    Deploy to Staging         :c1, after b2, 1d
    User Acceptance           :c2, after c1, 3d
    Deploy to Production      :c3, after c2, 1d
```

## Technical Debt Map

```mermaid
quadrantChart
    title Technical Debt Distribution
    x-axis Low Impact --> High Impact
    y-axis Low Urgency --> High Urgency
    quadrant-1 "Plan for Future"
    quadrant-2 "Address Soon"
    quadrant-3 "Monitor"
    quadrant-4 "Immediate Action"
    
    "Inconsistent Error Handling": [0.3, 0.4]
    "Missing Documentation": [0.5, 0.3]
    "Old GitHub Integration": [0.8, 0.9]
    "Large Controller Methods": [0.7, 0.6]
    "Outdated Dependencies": [0.6, 0.5]
    "Inefficient Queries": [0.8, 0.7]
    "Security Vulnerabilities": [0.9, 0.9]
    "Test Coverage Gaps": [0.7, 0.5]
```

## AI Orchestration Flow

```mermaid
flowchart TD
    Request[Optimization Request] --> Orchestrator[AI Orchestrator]
    
    Orchestrator --> ProviderSelector{Provider Selector}
    ProviderSelector --> Groq[Groq Provider]
    ProviderSelector --> OpenAI[OpenAI Provider]
    ProviderSelector --> Anthropic[Anthropic Provider]
    
    Groq --> PromptEngine[Prompt Engine]
    OpenAI --> PromptEngine
    Anthropic --> PromptEngine
    
    PromptEngine --> CodeAnalysis[Code Analysis]
    CodeAnalysis --> OpportunityIdentification[Opportunity Identification]
    OpportunityIdentification --> SuggestionGeneration[Suggestion Generation]
    SuggestionGeneration --> Response[Optimization Response]
    
    classDef process fill:#bbf,stroke:#333,stroke-width:1px;
    classDef provider fill:#bfb,stroke:#333,stroke-width:1px;
    classDef io fill:#fbf,stroke:#333,stroke-width:1px;
    
    class Orchestrator,PromptEngine,CodeAnalysis,OpportunityIdentification,SuggestionGeneration process;
    class Groq,OpenAI,Anthropic provider;
    class Request,Response io;
```

## Database Schema Relationships

```mermaid
erDiagram
    PULL_REQUEST ||--o{ PR_FILE : contains
    PULL_REQUEST ||--o{ OPTIMIZATION_SUGGESTION : has
    OPTIMIZATION_SUGGESTION ||--|| PR_FILE : "applies to"
    
    EVOLUTION_PROPOSAL ||--o{ CODE_VERSION : produces
    
    PROJECT ||--o{ ANALYSIS : contains
    ANALYSIS ||--o{ OPPORTUNITY : identifies
    OPPORTUNITY ||--o{ OPTIMIZATION : "results in"
    
    PULL_REQUEST {
        int id
        int pr_id
        string title
        string repo_name
        string html_url
        string status
        timestamp inserted_at
        timestamp updated_at
    }
    
    PR_FILE {
        int id
        int pull_request_id
        string filename
        string status
        string content
        timestamp inserted_at
        timestamp updated_at
    }
    
    OPTIMIZATION_SUGGESTION {
        int id
        int pull_request_id
        int pr_file_id
        string suggestion_type
        string description
        string original_code
        string optimized_code
        string severity
        timestamp inserted_at
        timestamp updated_at
    }
    
    EVOLUTION_PROPOSAL {
        int id
        string title
        string description
        string status
        timestamp scheduled_at
        timestamp applied_at
        timestamp inserted_at
        timestamp updated_at
    }
```

## Test Coverage Map

```mermaid
graph TD
    subgraph TestCoverage[Test Coverage by Module]
        direction LR
        GitHub[GitHub Integration]
        Infrastructure[Infrastructure]
        Evolution[Evolution]
        Optimization[Optimization]
        Analysis[Analysis]
        Core[Core]
    end
    
    subgraph TestTypes[Test Types]
        direction TB
        Unit[Unit Tests]
        Integration[Integration Tests]
        Property[Property Tests]
        DocTests[Doc Tests]
    end
    
    GitHub --- |60%| TestTypes
    Infrastructure --- |70%| TestTypes
    Evolution --- |85%| TestTypes
    Optimization --- |75%| TestTypes
    Analysis --- |80%| TestTypes
    Core --- |90%| TestTypes
    
    classDef high fill:#9f9,stroke:#333,stroke-width:1px;
    classDef medium fill:#ff9,stroke:#333,stroke-width:1px;
    classDef low fill:#f99,stroke:#333,stroke-width:1px;
    
    class Evolution,Core high;
    class Optimization,Analysis,Infrastructure medium;
    class GitHub low;
```

## Development Workflow

```mermaid
stateDiagram-v2
    direction LR
    
    [*] --> Start
    
    state Development {
        Start --> CodeChanges: Implement Feature
        CodeChanges --> UnitTests: Write Tests
        UnitTests --> PRCreation: Create PR
    }
    
    state CIFlow {
        PRCreation --> LintCheck: Run Linters
        LintCheck --> TestSuite: Run Tests
        TestSuite --> CodeCoverage: Check Coverage
    }
    
    state OptimizationFlow {
        CodeCoverage --> ACEAnalysis: ACE Analysis
        ACEAnalysis --> CodeSuggestions: Generate Suggestions
        CodeSuggestions --> PRComments: Add Comments
    }
    
    state ReviewFlow {
        PRComments --> CodeReview: Developer Review
        CodeReview --> ApplySuggestions: Apply Suggestions
        ApplySuggestions --> PRMerge: Merge PR
    }
    
    PRMerge --> [*]
```

## File Modification Frequency

```mermaid
xychart-beta
    title "File Modification Frequency"
    x-axis [Service, Controller, Model, LiveView, GitHubAPI, Orchestrator, Router, Config]
    y-axis "Modifications" 0 --> 120
    bar [85, 75, 30, 65, 110, 95, 25, 40]
    
    line [75, 60, 25, 55, 95, 80, 15, 30]
``` 