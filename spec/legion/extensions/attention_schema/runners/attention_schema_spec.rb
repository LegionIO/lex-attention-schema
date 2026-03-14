# frozen_string_literal: true

RSpec.describe Legion::Extensions::AttentionSchema::Runners::AttentionSchema do
  let(:client) { Legion::Extensions::AttentionSchema::Client.new }

  describe '#focus_on' do
    it 'focuses on a target' do
      result = client.focus_on(target: :task, domain: :work, reason: 'priority', source: :external)
      expect(result[:success]).to be true
      expect(result[:target]).to eq('task')
      expect(result[:awareness_level]).to be > 0
      expect(result[:label]).to be_a(Symbol)
    end

    it 'boosts on re-focus' do
      first = client.focus_on(target: :task, domain: :work, reason: 'r', source: :s)
      second = client.focus_on(target: :task, domain: :work, reason: 'r', source: :s)
      expect(second[:awareness_level]).to be > first[:awareness_level]
    end
  end

  describe '#defocus' do
    it 'removes a target' do
      client.focus_on(target: :task, domain: :work, reason: 'r', source: :s)
      result = client.defocus(target: :task)
      expect(result[:success]).to be true
      expect(result[:removed]).to be true
    end

    it 'returns removed: false for unknown' do
      result = client.defocus(target: :missing)
      expect(result[:removed]).to be false
    end
  end

  describe '#am_i_aware_of' do
    it 'returns aware: true for focused target' do
      client.focus_on(target: :task, domain: :work, reason: 'r', source: :s)
      result = client.am_i_aware_of(target: :task)
      expect(result[:success]).to be true
      expect(result[:aware]).to be true
    end

    it 'returns aware: false for unknown target' do
      result = client.am_i_aware_of(target: :unknown)
      expect(result[:aware]).to be false
    end
  end

  describe '#report_awareness' do
    it 'returns awareness report' do
      client.focus_on(target: :task, domain: :work, reason: 'priority', source: :external)
      result = client.report_awareness
      expect(result[:success]).to be true
      expect(result[:report]).to be_a(String)
      expect(result[:items]).to be_an(Array)
    end
  end

  describe '#attention_state' do
    it 'returns current state' do
      result = client.attention_state
      expect(result[:success]).to be true
      expect(result[:state]).to be_a(Symbol)
      expect(result[:label]).to be_a(String)
    end
  end

  describe '#model_other_attention' do
    it 'records other agent attention' do
      result = client.model_other_attention(agent_id: :agent_a, target: :task, awareness: 0.8)
      expect(result[:success]).to be true
      expect(result[:agent_id]).to eq(:agent_a)
    end
  end

  describe '#query_other_attention' do
    it 'queries modeled attention' do
      client.model_other_attention(agent_id: :agent_a, target: :task, awareness: 0.8)
      result = client.query_other_attention(agent_id: :agent_a)
      expect(result[:success]).to be true
      expect(result[:model]).not_to be_nil
    end

    it 'returns nil model for unknown agent' do
      result = client.query_other_attention(agent_id: :unknown)
      expect(result[:model]).to be_nil
    end
  end

  describe '#meta_check' do
    it 'returns meta-attention signals' do
      result = client.meta_check
      expect(result[:success]).to be true
      expect(result[:state]).to be_a(Symbol)
      expect(result[:signals]).to be_an(Array)
    end
  end

  describe '#update_meta_accuracy' do
    it 'updates meta-accuracy with feedback' do
      result = client.update_meta_accuracy(was_correct: true)
      expect(result[:success]).to be true
      expect(result[:meta_accuracy]).to be > 0.5
    end
  end

  describe '#decay_schema' do
    it 'decays and reports' do
      client.focus_on(target: :task, domain: :work, reason: 'r', source: :s)
      result = client.decay_schema
      expect(result[:success]).to be true
      expect(result[:before]).to eq(1)
      expect(result).to have_key(:after)
      expect(result).to have_key(:pruned)
    end
  end

  describe '#schema_stats' do
    it 'returns stats hash' do
      result = client.schema_stats
      expect(result[:success]).to be true
      expect(result[:stats]).to include(:state, :schema_size, :meta_accuracy)
    end

    it 'reports zero schema_size when empty' do
      result = client.schema_stats
      expect(result[:stats][:schema_size]).to eq(0)
    end

    it 'includes items array in stats' do
      client.focus_on(target: :task, domain: :work, reason: 'r', source: :s)
      result = client.schema_stats
      expect(result[:stats][:items]).to be_an(Array)
      expect(result[:stats][:items].size).to eq(1)
    end
  end

  describe '#focus_on schema_size tracking' do
    it 'tracks schema_size correctly through multiple targets' do
      client.focus_on(target: :a, domain: :d, reason: 'r', source: :s)
      r2 = client.focus_on(target: :b, domain: :d, reason: 'r', source: :s)
      r3 = client.focus_on(target: :c, domain: :d, reason: 'r', source: :s)
      expect(r2[:schema_size]).to eq(2)
      expect(r3[:schema_size]).to eq(3)
    end
  end

  describe '#report_awareness empty state' do
    it 'returns empty items when nothing focused' do
      result = client.report_awareness
      expect(result[:items]).to be_empty
    end

    it 'includes state_label string' do
      result = client.report_awareness
      expect(result[:state_label]).to be_a(String)
    end
  end

  describe '#meta_check state labeling' do
    it 'returns :distracted state with empty schema' do
      result = client.meta_check
      expect(result[:state]).to eq(:distracted)
    end

    it 'returns numeric top_awareness and avg_awareness' do
      result = client.meta_check
      expect(result[:top_awareness]).to be_a(Float)
      expect(result[:avg_awareness]).to be_a(Float)
    end
  end

  describe '#update_meta_accuracy boundary behavior' do
    it 'correct=false reduces meta_accuracy below initial' do
      result = client.update_meta_accuracy(was_correct: false)
      expect(result[:meta_accuracy]).to be < 0.5
    end

    it 'returns the was_correct value echoed back' do
      result = client.update_meta_accuracy(was_correct: false)
      expect(result[:was_correct]).to be false
    end
  end
end
