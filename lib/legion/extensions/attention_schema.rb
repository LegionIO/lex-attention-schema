# frozen_string_literal: true

require 'legion/extensions/attention_schema/version'
require 'legion/extensions/attention_schema/helpers/constants'
require 'legion/extensions/attention_schema/helpers/schema_item'
require 'legion/extensions/attention_schema/helpers/attention_schema_model'
require 'legion/extensions/attention_schema/runners/attention_schema'
require 'legion/extensions/attention_schema/client'

module Legion
  module Extensions
    module AttentionSchema
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
