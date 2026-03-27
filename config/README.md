# Conversational AI Agent

This directory contains a realistic human-like conversational AI agent implementation.

## Overview

The `agent.py` file implements a voice-based conversational agent that simulates realistic human behavior, including:

- **Human-like imperfections**: Interrupting, not listening, talking out of turn
- **Emotional reactions**: Excitement, frustration, curiosity, and more
- **Personality traits**: Configurable patience, talkativeness, agreeableness, etc.
- **Function calling**: Speech speed adjustment, volume control, web search

## Prerequisites

The agent requires the following environment variables:

- `GOOGLE_API_KEY` - Google API key for Gemini LLM (required)
- `CARTESIA_API_KEY` - Cartesia API key for text-to-speech (required)
- `DAILY_ROOM_URL` - Daily.co room URL for video conferencing (optional, can be configured automatically)
- `DAILY_API_KEY` - Daily.co API key (optional)
- `EXA_API_KEY` - Exa API key for web search functionality (optional, only needed if web search is enabled)

## Usage

```python
import asyncio
from config.agent import RealisticHumanAgent

async def main():
    # Create an agent with default configuration
    agent = RealisticHumanAgent()

    # Or create with custom personality
    agent = RealisticHumanAgent({
        "name": "Marcus",
        "personality": {
            "patience": 5,
            "talkativeness": 7,
            "interruption": 4,
            "listening": 6,
            "agreeableness": 5,
            "emotionality": 6,
        },
        "behaviors": {
            "interrupt_probability": 25,
            "ignore_probability": 15,
            "talk_out_of_turn_probability": 20,
            "emotional_reaction_probability": 30,
        }
    })

    # Run the agent
    await agent.run()

if __name__ == "__main__":
    asyncio.run(main())
```

## Configuration

### Personality Traits (0-10 scale)

- **patience**: How patient the agent is (0: very impatient, 10: extremely patient)
- **talkativeness**: How much the agent talks (0: laconic, 10: won't stop talking)
- **interruption**: How often the agent interrupts (0: never, 10: constantly)
- **listening**: How well the agent listens (0: ignores you, 10: remembers everything)
- **agreeableness**: How agreeable the agent is (0: argumentative, 10: agrees with everything)
- **emotionality**: How emotional the agent gets (0: flat, 10: extreme reactions)

### Behavior Probabilities (0-100%)

- **interrupt_probability**: Chance to interrupt during user speech
- **ignore_probability**: Chance to ignore part of what user said
- **talk_out_of_turn_probability**: Chance to suddenly speak without prompt
- **emotional_reaction_probability**: Chance to have an emotional reaction

### Function Calling

- **enable_function_calling**: Enable function calling capabilities (default: True)
- **enable_speech_speed_adjustment**: Allow adjusting speech speed (default: True)
- **enable_web_search**: Enable web search via Exa API (default: True)

## Pre-defined Personalities

The agent includes several pre-defined personality templates:

1. **Passionate Debater**: Loves to debate, gets heated in discussions
2. **Absent-Minded Professor**: Patient explainer but often lost in thought
3. **Anxious Overthinker**: Hyper-aware of details, emotionally sensitive
4. **Charismatic Storyteller**: Tells engaging stories, very animated
5. **Grumpy Perfectionist**: Critical of imperfections, catches every detail

See the `main()` function in `agent.py` for examples.

## Architecture

The agent is built using the Pipecat framework and consists of:

- **Frame Processors**: Handle audio, transcription, and behavioral modifications
- **LLM Integration**: Google Gemini for conversation and transcription
- **TTS Integration**: Cartesia for realistic text-to-speech
- **Transport**: Daily.co for real-time video/audio communication

## Error Handling

The agent validates:

- Personality traits are in the 0-10 range
- Behavior probabilities are in the 0-100 range
- Required environment variables are set
- Configuration values are of correct types

Raises `ValueError` with descriptive messages for invalid configurations.

## Type Safety

The agent code includes comprehensive type hints for better IDE support and type checking. Use `mypy` or similar tools for static type checking:

```bash
mypy config/agent.py
```

## Development

To contribute improvements:

1. Add type hints to all new functions
2. Add comprehensive docstrings
3. Validate all configuration inputs
4. Handle errors gracefully with descriptive messages
5. Follow existing code style and patterns
