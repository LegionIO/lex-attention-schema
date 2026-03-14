# frozen_string_literal: true

RSpec.describe Legion::Extensions::AttentionSchema::Client do
  subject(:client) { described_class.new }

  it 'includes Runners::AttentionSchema' do
    expect(described_class.ancestors).to include(Legion::Extensions::AttentionSchema::Runners::AttentionSchema)
  end

  it 'supports full attention lifecycle' do
    # Focus on items
    client.focus_on(target: :code_review, domain: :work, reason: 'PR needs review', source: :external)
    client.focus_on(target: :test_results, domain: :ci, reason: 'tests running', source: :internal)

    # Query awareness
    aware = client.am_i_aware_of(target: :code_review)
    expect(aware[:aware]).to be true

    # Report
    report = client.report_awareness
    expect(report[:items].size).to eq(2)

    # Model another agent
    client.model_other_attention(agent_id: :validator, target: :code_review, awareness: 0.9)
    other = client.query_other_attention(agent_id: :validator)
    expect(other[:model]).not_to be_nil

    # Meta-check
    meta = client.meta_check
    expect(meta[:schema_size]).to eq(2)

    # Meta-accuracy feedback
    client.update_meta_accuracy(was_correct: true)

    # Decay
    client.decay_schema

    # Stats
    stats = client.schema_stats
    expect(stats[:success]).to be true

    # Defocus
    client.defocus(target: :test_results)
    final = client.am_i_aware_of(target: :test_results)
    expect(final[:aware]).to be false
  end
end
