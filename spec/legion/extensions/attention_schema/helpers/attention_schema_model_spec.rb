# frozen_string_literal: true

RSpec.describe Legion::Extensions::AttentionSchema::Helpers::AttentionSchemaModel do
  subject(:model) { described_class.new }

  let(:constants) { Legion::Extensions::AttentionSchema::Helpers::Constants }

  describe '#focus_on' do
    it 'adds an item to the schema' do
      item = model.focus_on(target: :task, domain: :work, reason: 'priority', source: :external)
      expect(item.target).to eq('task')
      expect(model.schema_size).to eq(1)
    end

    it 'boosts existing items on re-focus' do
      model.focus_on(target: :task, domain: :work, reason: 'init', source: :external)
      first_level = model.schema_items['task'].awareness_level
      model.focus_on(target: :task, domain: :work, reason: 'again', source: :external)
      expect(model.schema_items['task'].awareness_level).to be > first_level
      expect(model.schema_size).to eq(1)
    end

    it 'prunes to capacity when full' do
      constants::MAX_SCHEMA_ITEMS.times do |i|
        model.focus_on(target: "item_#{i}", domain: :d, reason: :r, source: :s)
      end
      expect(model.schema_size).to eq(constants::MAX_SCHEMA_ITEMS)
      model.focus_on(target: :overflow, domain: :d, reason: :r, source: :s)
      expect(model.schema_size).to eq(constants::MAX_SCHEMA_ITEMS)
    end

    it 'records focus event in history' do
      model.focus_on(target: :task, domain: :work, reason: 'test', source: :external)
      expect(model.attention_history.size).to eq(1)
      expect(model.attention_history.first[:event]).to eq(:focused)
    end

    it 'records refocused event on re-focus' do
      model.focus_on(target: :task, domain: :work, reason: 'init', source: :external)
      model.focus_on(target: :task, domain: :work, reason: 'again', source: :external)
      expect(model.attention_history.last[:event]).to eq(:refocused)
    end
  end

  describe '#defocus' do
    it 'removes an item from the schema' do
      model.focus_on(target: :task, domain: :work, reason: 'r', source: :s)
      removed = model.defocus(target: :task)
      expect(removed).to be true
      expect(model.schema_size).to eq(0)
    end

    it 'returns false for unknown target' do
      expect(model.defocus(target: :missing)).to be false
    end
  end

  describe '#am_i_aware_of' do
    it 'returns aware: true for focused items' do
      model.focus_on(target: :task, domain: :work, reason: 'r', source: :s)
      result = model.am_i_aware_of(target: :task)
      expect(result[:aware]).to be true
      expect(result[:awareness_level]).to be > 0
    end

    it 'returns aware: false for unknown targets' do
      result = model.am_i_aware_of(target: :unknown)
      expect(result[:aware]).to be false
      expect(result[:awareness_level]).to eq(0.0)
      expect(result[:label]).to eq(:unconscious)
    end
  end

  describe '#attention_state' do
    it 'returns :distracted when empty' do
      expect(model.attention_state).to eq(:distracted)
    end

    it 'returns :focused with a moderate item' do
      model.focus_on(target: :task, domain: :work, reason: 'r', source: :s)
      model.schema_items['task'].awareness_level = 0.7
      expect(model.attention_state).to eq(:focused)
    end

    it 'returns :hyperfocused with high awareness' do
      model.focus_on(target: :task, domain: :work, reason: 'r', source: :s)
      model.schema_items['task'].awareness_level = 0.9
      expect(model.attention_state).to eq(:hyperfocused)
    end

    it 'returns :drifting when average is low with few items' do
      model.focus_on(target: :task, domain: :work, reason: 'r', source: :s)
      model.schema_items['task'].awareness_level = 0.15
      expect(model.attention_state).to eq(:drifting)
    end

    it 'returns :distracted with many low-awareness items' do
      5.times { |i| model.focus_on(target: "t_#{i}", domain: :d, reason: :r, source: :s) }
      model.schema_items.each_value { |v| v.awareness_level = 0.15 }
      expect(model.attention_state).to eq(:distracted)
    end
  end

  describe '#report_awareness' do
    it 'reports no items when empty' do
      report = model.report_awareness
      expect(report[:state]).to eq(:distracted)
      expect(report[:items]).to be_empty
      expect(report[:report]).to include('No active')
    end

    it 'generates summary with items' do
      model.focus_on(target: :task, domain: :work, reason: 'priority', source: :external)
      report = model.report_awareness
      expect(report[:report]).to include('task')
      expect(report[:items].size).to eq(1)
    end

    it 'includes secondary items in report' do
      model.focus_on(target: :a, domain: :work, reason: 'r', source: :s)
      model.focus_on(target: :b, domain: :play, reason: 'r', source: :s)
      report = model.report_awareness
      expect(report[:items].size).to eq(2)
      expect(report[:report]).to include('Also attending to')
    end
  end

  describe '#model_other_attention' do
    it 'records another agent attention model' do
      model.model_other_attention(agent_id: :agent_a, target: :task, awareness: 0.8)
      result = model.query_other_attention(agent_id: :agent_a)
      expect(result[:target]).to eq('task')
      expect(result[:awareness]).to eq(0.8)
    end

    it 'clamps awareness' do
      model.model_other_attention(agent_id: :agent_a, target: :task, awareness: 1.5)
      result = model.query_other_attention(agent_id: :agent_a)
      expect(result[:awareness]).to eq(1.0)
    end

    it 'returns nil for unknown agent' do
      expect(model.query_other_attention(agent_id: :unknown)).to be_nil
    end

    it 'prunes oldest social model when full' do
      constants::MAX_SOCIAL_MODELS.times do |i|
        model.model_other_attention(agent_id: "agent_#{i}", target: :t, awareness: 0.5)
      end
      model.model_other_attention(agent_id: :overflow, target: :t, awareness: 0.5)
      expect(model.social_models.size).to eq(constants::MAX_SOCIAL_MODELS)
    end
  end

  describe '#meta_check' do
    it 'returns meta-attention state' do
      result = model.meta_check
      expect(result).to include(:state, :signals, :top_awareness, :avg_awareness, :schema_size, :meta_accuracy)
    end

    it 'includes :drifting signal when distracted' do
      result = model.meta_check
      expect(result[:signals]).to include(:drifting)
    end

    it 'includes :hyperfocus signal when hyperfocused' do
      model.focus_on(target: :task, domain: :work, reason: 'r', source: :s)
      model.schema_items['task'].awareness_level = 0.9
      result = model.meta_check
      expect(result[:signals]).to include(:hyperfocus)
    end

    it 'includes :normal when state is normal' do
      model.focus_on(target: :task, domain: :work, reason: 'r', source: :s)
      model.schema_items['task'].awareness_level = 0.5
      result = model.meta_check
      expect(result[:signals]).to include(:normal)
    end
  end

  describe '#update_meta_accuracy' do
    it 'increases accuracy when correct' do
      before = model.meta_accuracy
      model.update_meta_accuracy(was_correct: true)
      expect(model.meta_accuracy).to be > before
    end

    it 'decreases accuracy when incorrect' do
      before = model.meta_accuracy
      model.update_meta_accuracy(was_correct: false)
      expect(model.meta_accuracy).to be < before
    end
  end

  describe '#decay_all' do
    it 'decays all items' do
      model.focus_on(target: :task, domain: :work, reason: 'r', source: :s)
      before = model.schema_items['task'].awareness_level
      model.decay_all
      expect(model.schema_items['task']&.awareness_level || 0).to be < before
    end

    it 'prunes faded items' do
      model.focus_on(target: :task, domain: :work, reason: 'r', source: :s)
      model.schema_items['task'].awareness_level = constants::AWARENESS_FLOOR + 0.01
      model.decay_all
      expect(model.schema_size).to eq(0)
    end
  end

  describe '#to_h' do
    it 'returns stats hash' do
      model.focus_on(target: :task, domain: :work, reason: 'r', source: :s)
      h = model.to_h
      expect(h).to include(:state, :state_label, :schema_size, :meta_accuracy, :top_awareness, :avg_awareness, :social_models, :items)
      expect(h[:schema_size]).to eq(1)
    end
  end
end
