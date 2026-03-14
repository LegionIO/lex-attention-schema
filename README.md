# lex-attention-schema

Graziano's Attention Schema Theory for brain-modeled agentic AI — the agent maintains an internal model of its own attention process.

## What It Does

Implements Michael Graziano's Attention Schema Theory: the brain doesn't just attend to things — it builds a simplified internal model of the attention process itself. This model (the attention schema) is the basis for subjective awareness. This extension maintains that schema: a list of what the agent is currently aware of, how vividly, and in what attentional state. It also models other agents' attention for social cognition.

## Core Concept: The Attention Schema

The schema answers: "What am I currently paying attention to, and how aware am I of attending to it?"

```ruby
client.focus_on(target: :deployment_pipeline, domain: :infrastructure, reason: 'active incident')
# => { awareness_level: 0.3, label: :peripheral, schema_size: 1 }

client.am_i_aware_of(target: :deployment_pipeline)
# => { aware: true, awareness_level: 0.45, label: :dim }

client.attention_state
# => { state: :focused, label: 'actively attending' }

client.report_awareness
# => { state: :focused, items: [{ target: :deployment_pipeline, awareness: 0.45, label: :dim }] }
```

## Usage

```ruby
client = Legion::Extensions::AttentionSchema::Client.new

# Model another agent's attention
client.model_other_attention(agent_id: 'agent-2', target: :database, awareness: 0.8)

# Run meta-awareness check
client.meta_check
# => { state: :focused, signals: [], meta_accuracy: 0.72 }

# Provide accuracy feedback
client.update_meta_accuracy(was_correct: true)

# Schema decays automatically every 30s via Decay actor
```

## Integration

`meta_check` feeds into lex-tick's meta-awareness phase. `report_awareness` generates human-readable descriptions for governance and dream journals. `model_other_attention` supports multi-agent attention coordination via lex-mesh.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
