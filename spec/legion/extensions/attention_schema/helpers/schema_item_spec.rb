# frozen_string_literal: true

RSpec.describe Legion::Extensions::AttentionSchema::Helpers::SchemaItem do
  subject(:item) do
    described_class.new(target: 'task_queue', domain: :work, reason: 'priority', source: :external)
  end

  let(:constants) { Legion::Extensions::AttentionSchema::Helpers::Constants }

  describe '#initialize' do
    it 'sets attributes' do
      expect(item.target).to eq('task_queue')
      expect(item.domain).to eq(:work)
      expect(item.reason).to eq('priority')
      expect(item.source).to eq(:external)
    end

    it 'uses default awareness level' do
      expect(item.awareness_level).to eq(constants::DEFAULT_AWARENESS)
    end

    it 'clamps awareness to 0..1' do
      high = described_class.new(target: :x, domain: :d, reason: :r, source: :s, awareness_level: 1.5)
      low  = described_class.new(target: :y, domain: :d, reason: :r, source: :s, awareness_level: -0.5)
      expect(high.awareness_level).to eq(1.0)
      expect(low.awareness_level).to eq(0.0)
    end

    it 'records created_at' do
      expect(item.created_at).to be_a(Time)
    end
  end

  describe '#duration' do
    it 'returns elapsed time' do
      expect(item.duration).to be >= 0.0
    end
  end

  describe '#boost' do
    it 'increases awareness by AWARENESS_BOOST' do
      before = item.awareness_level
      item.boost
      expect(item.awareness_level).to eq(before + constants::AWARENESS_BOOST)
    end

    it 'caps at 1.0' do
      item.awareness_level = 0.95
      item.boost
      expect(item.awareness_level).to eq(1.0)
    end
  end

  describe '#decay' do
    it 'decreases awareness by AWARENESS_DECAY' do
      item.awareness_level = 0.5
      item.decay
      expect(item.awareness_level).to eq(0.5 - constants::AWARENESS_DECAY)
    end

    it 'does not drop below AWARENESS_FLOOR' do
      item.awareness_level = constants::AWARENESS_FLOOR + 0.001
      item.decay
      expect(item.awareness_level).to eq(constants::AWARENESS_FLOOR)
    end
  end

  describe '#faded?' do
    it 'returns true at floor' do
      item.awareness_level = constants::AWARENESS_FLOOR
      expect(item.faded?).to be true
    end

    it 'returns false above floor' do
      item.awareness_level = constants::AWARENESS_FLOOR + 0.01
      expect(item.faded?).to be false
    end
  end

  describe '#label' do
    it 'returns :vivid for high awareness' do
      item.awareness_level = 0.9
      expect(item.label).to eq(:vivid)
    end

    it 'returns :unconscious for very low awareness' do
      item.awareness_level = 0.1
      expect(item.label).to eq(:unconscious)
    end

    it 'returns :clear for mid-high awareness' do
      item.awareness_level = 0.7
      expect(item.label).to eq(:clear)
    end

    it 'returns :dim for mid awareness' do
      item.awareness_level = 0.5
      expect(item.label).to eq(:dim)
    end

    it 'returns :peripheral for low awareness' do
      item.awareness_level = 0.25
      expect(item.label).to eq(:peripheral)
    end
  end

  describe '#to_h' do
    it 'returns hash with all fields' do
      h = item.to_h
      expect(h).to include(:target, :domain, :awareness_level, :label, :reason, :source, :duration, :created_at)
      expect(h[:target]).to eq('task_queue')
    end
  end
end
