# lex-attention-schema

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Graziano's Attention Schema Theory for brain-modeled agentic AI. The agent maintains a simplified internal model of its own attention process, enabling awareness attribution, social attention modeling, meta-attention monitoring, and natural-language attention reports. The attention schema is the brain's simplified model of what attention is and where it is directed — the basis for subjective awareness.

## Gem Info

- **Gem name**: `lex-attention-schema`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::AttentionSchema`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/attention_schema/
  attention_schema.rb             # Main extension module
  version.rb                      # VERSION = '0.1.0'
  client.rb                       # Client wrapper
  actors/
    decay.rb                      # Every 30s schema decay actor
  helpers/
    constants.rb                  # Schema limits, decay/boost rates, state labels
    schema_item.rb                # SchemaItem value object (target, domain, awareness_level)
    attention_schema_model.rb     # AttentionSchemaModel — schema CRUD, social modeling, meta-check
  runners/
    attention_schema.rb           # Runner module with 9 public methods
spec/
  (spec files)
```

## Key Constants

```ruby
MAX_SCHEMA_ITEMS     = 15       # max simultaneous schema entries
MAX_SOCIAL_MODELS    = 10       # max other agents modeled
SCHEMA_UPDATE_ALPHA  = 0.15     # EMA alpha for schema updates
DEFAULT_AWARENESS    = 0.3      # new item awareness level
AWARENESS_FLOOR      = 0.05     # pruned below this
AWARENESS_DECAY      = 0.02     # per-tick decay
AWARENESS_BOOST      = 0.15     # boost on re-focus of existing item
DRIFT_THRESHOLD      = 0.3      # avg awareness below this → drifting
HYPERFOCUS_THRESHOLD = 0.85     # top item above this → hyperfocused
META_ATTENTION_ALPHA = 0.1      # EMA for meta-accuracy tracking
MAX_HISTORY          = 200

AWARENESS_LABELS = {
  (0.8..) => :vivid, (0.6...0.8) => :clear, (0.4...0.6) => :dim,
  (0.2...0.4) => :peripheral, (..0.2) => :unconscious
}
ATTENTION_STATE_LABELS = {
  hyperfocused: 'deeply engaged', focused: 'actively attending',
  normal: 'casually aware', drifting: 'attention waning',
  distracted: 'attention scattered'
}
```

## Runners

### `Runners::AttentionSchema`

All methods delegate to a private `@schema_model` (`Helpers::AttentionSchemaModel` instance).

- `focus_on(target:, domain:, reason:, source: :external)` — add/boost a target in the schema; returns awareness level and schema size
- `defocus(target:)` — remove a target from the schema
- `am_i_aware_of(target:)` — query: is this target currently in the attention schema?
- `report_awareness` — natural-language attention report: state, items with awareness levels
- `attention_state` — current attention state symbol: `:hyperfocused`, `:focused`, `:normal`, `:drifting`, `:distracted`
- `model_other_attention(agent_id:, target:, awareness:)` — model what another agent is paying attention to (social AST)
- `query_other_attention(agent_id:)` — retrieve the attention model for another agent
- `meta_check` — detect attention issues: drifting, hyperfocus, distracted; returns signals list
- `update_meta_accuracy(was_correct:)` — feedback loop: was the schema's prediction of actual attention correct?
- `decay_schema` — decay all items and prune below floor (also called by Decay actor)
- `schema_stats` — full stats hash

## Actors

### `Actors::Decay`
`Every` actor with 30-second interval. Calls `decay_schema` to keep the schema current without caller intervention.

## Integration Points

This extension implements Graziano's AST: the attention schema is what makes the agent "aware" that it is attending to something. `am_i_aware_of` is the core introspection method. `model_other_attention` supports multi-agent scenarios in lex-mesh where agents need to model each other's attention. `meta_check` output feeds into lex-tick's meta-awareness phase to detect and correct attentional dysfunction. `report_awareness` generates human-readable descriptions for lex-dream's journal or governance reporting.

## Development Notes

- Re-focusing an existing schema item boosts awareness by `AWARENESS_BOOST` rather than resetting to `DEFAULT_AWARENESS`
- `meta_accuracy` is tracked via EMA — a running estimate of how well the schema predicts actual attention; not currently used to adjust behavior but available as a calibration signal
- Social models (`@social_models`) are keyed by `agent_id`, storing the agent's modeled attention target and awareness level
- `attention_state` thresholds: top item > 0.85 → hyperfocused; avg < 0.3 → drifting; multiple items at similar high levels → distracted
