# frozen_string_literal: true

module Legion
  module Extensions
    module AttentionSchema
      module Helpers
        module Constants
          # Maximum items the schema can model simultaneously
          MAX_SCHEMA_ITEMS = 15

          # Maximum other agents whose attention we model socially
          MAX_SOCIAL_MODELS = 10

          # EMA alpha for schema update speed
          SCHEMA_UPDATE_ALPHA = 0.15

          # Default awareness level for newly focused items
          DEFAULT_AWARENESS = 0.3

          # Minimum awareness before item is pruned from schema
          AWARENESS_FLOOR = 0.05

          # Per-tick decay applied to all schema items
          AWARENESS_DECAY = 0.02

          # Awareness boost applied when re-focusing an existing item
          AWARENESS_BOOST = 0.15

          # Below this awareness average: attention is drifting
          DRIFT_THRESHOLD = 0.3

          # Above this awareness (for top item): attention is hyper-focused
          HYPERFOCUS_THRESHOLD = 0.85

          # EMA alpha for meta-attention accuracy tracking
          META_ATTENTION_ALPHA = 0.1

          # Maximum entries kept in attention history ring buffer
          MAX_HISTORY = 200

          # Human-readable labels keyed by awareness level range
          AWARENESS_LABELS = {
            (0.8..)     => :vivid,
            (0.6...0.8) => :clear,
            (0.4...0.6) => :dim,
            (0.2...0.4) => :peripheral,
            (..0.2)     => :unconscious
          }.freeze

          # Human-readable attention-state labels
          ATTENTION_STATE_LABELS = {
            hyperfocused: 'deeply engaged',
            focused:      'actively attending',
            normal:       'casually aware',
            drifting:     'attention waning',
            distracted:   'attention scattered'
          }.freeze
        end
      end
    end
  end
end
