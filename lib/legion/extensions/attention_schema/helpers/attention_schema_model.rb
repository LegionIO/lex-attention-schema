# frozen_string_literal: true

module Legion
  module Extensions
    module AttentionSchema
      module Helpers
        class AttentionSchemaModel
          include Constants

          attr_reader :schema_items, :social_models, :meta_accuracy, :attention_history

          def initialize
            @schema_items    = {}    # target => SchemaItem
            @social_models   = {}    # agent_id => { target:, awareness:, updated_at: }
            @meta_accuracy   = 0.5   # EMA confidence in schema self-accuracy
            @attention_history = []  # ring buffer of { target:, event:, at: }
          end

          # --- Focus Management ---

          # Add or boost an item in the attention schema
          def focus_on(target:, domain:, reason:, source:)
            target = target.to_s
            if @schema_items.key?(target)
              @schema_items[target].boost
              record_history(target, :refocused)
            else
              prune_to_capacity if @schema_items.size >= MAX_SCHEMA_ITEMS
              @schema_items[target] = SchemaItem.new(
                target:          target,
                domain:          domain,
                reason:          reason,
                source:          source,
                awareness_level: DEFAULT_AWARENESS + AWARENESS_BOOST
              )
              record_history(target, :focused)
            end
            @schema_items[target]
          end

          # Remove an item from the schema entirely
          def defocus(target:)
            target = target.to_s
            removed = @schema_items.delete(target)
            record_history(target, :defocused) if removed
            !removed.nil?
          end

          # --- Awareness Query (core AST operation) ---

          # "Am I aware of X?" — the central Graziano query
          def am_i_aware_of(target:)
            item = @schema_items[target.to_s]
            return { aware: false, awareness_level: 0.0, label: :unconscious } unless item

            { aware: item.awareness_level > AWARENESS_FLOOR, awareness_level: item.awareness_level.round(4), label: item.label }
          end

          # --- Attention Report ---

          # Natural-language-style summary of current attention state
          def report_awareness
            state     = attention_state
            state_str = ATTENTION_STATE_LABELS[state] || 'in an unknown state'
            top_items = top_schema_items(3)

            return { state: state, state_label: state_str, report: 'No active attention targets.', items: [] } if top_items.empty?

            primary  = top_items.first
            summary  = "I am #{state_str}, primarily attending to '#{primary[:target]}' " \
                       "(#{primary[:label]}, #{primary[:awareness_level]}). " \
                       "Reason: #{primary[:reason]}."

            if top_items.size > 1
              secondary = top_items[1..]
                          .map { |i| "'#{i[:target]}' (#{i[:label]})" }
                          .join(', ')
              summary += " Also attending to: #{secondary}."
            end

            { state: state, state_label: state_str, report: summary, items: top_items }
          end

          # --- Attention State Classification ---

          # Overall qualitative attention state
          def attention_state
            return :distracted if @schema_items.empty?

            top = top_awareness
            avg = average_awareness

            if top >= HYPERFOCUS_THRESHOLD
              :hyperfocused
            elsif avg < DRIFT_THRESHOLD && @schema_items.size > 3
              :distracted
            elsif avg < DRIFT_THRESHOLD
              :drifting
            elsif top >= 0.6
              :focused
            else
              :normal
            end
          end

          # --- Social Attention Modeling ---

          # Record what another agent appears to be attending to
          def model_other_attention(agent_id:, target:, awareness:)
            agent_id = agent_id.to_s
            prune_social_models if @social_models.size >= MAX_SOCIAL_MODELS && !@social_models.key?(agent_id)
            @social_models[agent_id] = {
              target:     target.to_s,
              awareness:  awareness.clamp(0.0, 1.0),
              updated_at: Time.now.utc
            }
          end

          # Query what another agent is modeled as attending to
          def query_other_attention(agent_id:)
            @social_models[agent_id.to_s]
          end

          # --- Meta-Attention ---

          # Assess whether meta-attention signals are active
          def meta_check
            state = attention_state
            signals = []

            signals << :drifting   if %i[drifting distracted].include?(state)
            signals << :hyperfocus if state == :hyperfocused
            signals << :normal     if signals.empty?

            top = top_awareness
            avg = average_awareness

            {
              state:         state,
              signals:       signals,
              top_awareness: top.round(4),
              avg_awareness: avg.round(4),
              schema_size:   @schema_items.size,
              meta_accuracy: @meta_accuracy.round(4)
            }
          end

          # Update the EMA tracking how well the schema predicted actual attention
          def update_meta_accuracy(was_correct:)
            correction = was_correct ? 1.0 : 0.0
            @meta_accuracy += (META_ATTENTION_ALPHA * (correction - @meta_accuracy))
          end

          # --- Decay ---

          # Apply per-tick decay to all schema items and prune faded ones
          def decay_all
            @schema_items.each_value(&:decay)
            @schema_items.reject! { |_, item| item.faded? }
          end

          # --- Accessors ---

          def schema_size
            @schema_items.size
          end

          def to_h
            {
              state:         attention_state,
              state_label:   ATTENTION_STATE_LABELS[attention_state],
              schema_size:   schema_size,
              meta_accuracy: @meta_accuracy.round(4),
              top_awareness: top_awareness.round(4),
              avg_awareness: average_awareness.round(4),
              social_models: @social_models.size,
              items:         @schema_items.values.map(&:to_h)
            }
          end

          private

          def top_awareness
            return 0.0 if @schema_items.empty?

            @schema_items.values.map(&:awareness_level).max
          end

          def average_awareness
            return 0.0 if @schema_items.empty?

            vals = @schema_items.values.map(&:awareness_level)
            vals.sum / vals.size
          end

          def top_schema_items(n = 3)
            @schema_items.values
                         .sort_by { |i| -i.awareness_level }
                         .first(n)
                         .map(&:to_h)
          end

          def prune_to_capacity
            # Remove the item with the lowest awareness
            weakest = @schema_items.min_by { |_, item| item.awareness_level }&.first
            @schema_items.delete(weakest) if weakest
          end

          def prune_social_models
            oldest = @social_models.min_by { |_, v| v[:updated_at] }&.first
            @social_models.delete(oldest) if oldest
          end

          def record_history(target, event)
            @attention_history << { target: target, event: event, at: Time.now.utc }
            @attention_history.shift while @attention_history.size > MAX_HISTORY
          end
        end
      end
    end
  end
end
