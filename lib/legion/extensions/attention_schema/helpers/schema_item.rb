# frozen_string_literal: true

module Legion
  module Extensions
    module AttentionSchema
      module Helpers
        class SchemaItem
          include Constants

          attr_reader :target, :domain, :reason, :source, :created_at
          attr_accessor :awareness_level

          def initialize(target:, domain:, reason:, source:, awareness_level: DEFAULT_AWARENESS)
            @target          = target
            @domain          = domain
            @reason          = reason
            @source          = source
            @awareness_level = awareness_level.clamp(0.0, 1.0)
            @created_at      = Time.now.utc
          end

          # Duration in seconds since this item entered the schema
          def duration
            Time.now.utc - @created_at
          end

          # Apply a one-time boost (re-focus event)
          def boost
            @awareness_level = [@awareness_level + AWARENESS_BOOST, 1.0].min
          end

          # Apply per-tick decay
          def decay
            @awareness_level = [@awareness_level - AWARENESS_DECAY, AWARENESS_FLOOR].max
          end

          # True when awareness has dropped to the pruning floor
          def faded?
            @awareness_level <= AWARENESS_FLOOR
          end

          # Symbolic label describing current awareness intensity
          def label
            AWARENESS_LABELS.each { |range, lbl| return lbl if range.cover?(@awareness_level) }
            :unconscious
          end

          def to_h
            {
              target:          @target,
              domain:          @domain,
              awareness_level: @awareness_level.round(4),
              label:           label,
              reason:          @reason,
              source:          @source,
              duration:        duration.round(2),
              created_at:      @created_at
            }
          end
        end
      end
    end
  end
end
