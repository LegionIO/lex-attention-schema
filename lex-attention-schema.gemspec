# frozen_string_literal: true

require_relative 'lib/legion/extensions/attention_schema/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-attention-schema'
  spec.version       = Legion::Extensions::AttentionSchema::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Attention Schema'
  spec.description   = "Graziano's Attention Schema Theory for brain-modeled agentic AI — the agent " \
                       'maintains a simplified internal model of its own attention process, enabling ' \
                       'awareness attribution, social attention modeling, meta-attention monitoring, ' \
                       'and natural-language attention reports.'
  spec.homepage      = 'https://github.com/LegionIO/lex-attention-schema'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/LegionIO/lex-attention-schema'
  spec.metadata['documentation_uri']     = 'https://github.com/LegionIO/lex-attention-schema'
  spec.metadata['changelog_uri']         = 'https://github.com/LegionIO/lex-attention-schema'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/LegionIO/lex-attention-schema/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-attention-schema.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
