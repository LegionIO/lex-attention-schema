# frozen_string_literal: true

module Legion
  module Extensions
    module AttentionSchema
      module Runners
        module AttentionSchema
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          # Focus attention on a target — adds or boosts it in the schema
          def focus_on(target:, domain:, reason:, source: :external, **)
            Legion::Logging.debug "[attention_schema] focus_on: target=#{target} domain=#{domain} source=#{source}"
            item = schema_model.focus_on(target: target, domain: domain, reason: reason, source: source)
            {
              success:         true,
              target:          item.target,
              domain:          item.domain,
              awareness_level: item.awareness_level.round(4),
              label:           item.label,
              schema_size:     schema_model.schema_size
            }
          end

          # Remove a target from the attention schema
          def defocus(target:, **)
            Legion::Logging.debug "[attention_schema] defocus: target=#{target}"
            removed = schema_model.defocus(target: target)
            { success: true, target: target, removed: removed, schema_size: schema_model.schema_size }
          end

          # Core AST query: "am I aware of X?"
          def am_i_aware_of(target:, **)
            result = schema_model.am_i_aware_of(target: target)
            Legion::Logging.debug "[attention_schema] am_i_aware_of: target=#{target} aware=#{result[:aware]} level=#{result[:awareness_level]}"
            result.merge(success: true)
          end

          # Generate a natural-language attention awareness report
          def report_awareness(**)
            report = schema_model.report_awareness
            Legion::Logging.debug "[attention_schema] report_awareness: state=#{report[:state]} items=#{report[:items].size}"
            report.merge(success: true)
          end

          # Return the current qualitative attention state symbol
          def attention_state(**)
            state = schema_model.attention_state
            label = Helpers::Constants::ATTENTION_STATE_LABELS[state]
            Legion::Logging.debug "[attention_schema] attention_state: state=#{state}"
            { success: true, state: state, label: label }
          end

          # Model another agent's attention (social attention modeling)
          def model_other_attention(agent_id:, target:, awareness:, **)
            Legion::Logging.debug "[attention_schema] model_other: agent=#{agent_id} target=#{target} awareness=#{awareness}"
            schema_model.model_other_attention(agent_id: agent_id, target: target, awareness: awareness.to_f)
            { success: true, agent_id: agent_id, target: target, awareness: awareness.to_f.clamp(0.0, 1.0).round(4) }
          end

          # Query what another agent is modeled as attending to
          def query_other_attention(agent_id:, **)
            model = schema_model.query_other_attention(agent_id: agent_id)
            Legion::Logging.debug "[attention_schema] query_other: agent=#{agent_id} found=#{!model.nil?}"
            { success: true, agent_id: agent_id, model: model }
          end

          # Run meta-attention check: detect drifting, hyper-focus, etc.
          def meta_check(**)
            result = schema_model.meta_check
            Legion::Logging.debug "[attention_schema] meta_check: state=#{result[:state]} signals=#{result[:signals]}"
            result.merge(success: true)
          end

          # Record whether the schema accurately predicted actual attention (accuracy feedback)
          def update_meta_accuracy(was_correct:, **)
            schema_model.update_meta_accuracy(was_correct: was_correct)
            accuracy = schema_model.meta_accuracy
            Legion::Logging.debug "[attention_schema] meta_accuracy: was_correct=#{was_correct} accuracy=#{accuracy.round(3)}"
            { success: true, was_correct: was_correct, meta_accuracy: accuracy.round(4) }
          end

          # Tick decay: decay all schema items and prune faded ones
          def decay_schema(**)
            before = schema_model.schema_size
            schema_model.decay_all
            after = schema_model.schema_size
            Legion::Logging.debug "[attention_schema] decay: before=#{before} after=#{after} pruned=#{before - after}"
            {
              success: true,
              before:  before,
              after:   after,
              pruned:  before - after,
              state:   schema_model.attention_state
            }
          end

          # Return full schema stats snapshot
          def schema_stats(**)
            Legion::Logging.debug "[attention_schema] stats: size=#{schema_model.schema_size}"
            { success: true, stats: schema_model.to_h }
          end

          private

          def schema_model
            @schema_model ||= Helpers::AttentionSchemaModel.new
          end
        end
      end
    end
  end
end
