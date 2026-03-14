# frozen_string_literal: true

require 'legion/extensions/actors/every'

module Legion
  module Extensions
    module AttentionSchema
      module Actor
        class Decay < Legion::Extensions::Actors::Every
          def runner_class
            Legion::Extensions::AttentionSchema::Runners::AttentionSchema
          end

          def runner_function
            'decay_schema'
          end

          def time
            30
          end

          def run_now?
            false
          end

          def use_runner?
            false
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end
        end
      end
    end
  end
end
