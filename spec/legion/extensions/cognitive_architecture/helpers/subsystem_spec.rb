# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveArchitecture::Helpers::Subsystem do
  subject(:subsystem) { described_class.new(name: :test_sub, subsystem_type: :cognition) }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(subsystem.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores name as symbol' do
      expect(subsystem.name).to eq(:test_sub)
    end

    it 'stores subsystem_type as symbol' do
      expect(subsystem.subsystem_type).to eq(:cognition)
    end

    it 'defaults health to DEFAULT_HEALTH' do
      expect(subsystem.health).to eq(Legion::Extensions::CognitiveArchitecture::Helpers::Constants::DEFAULT_HEALTH)
    end

    it 'defaults status to active' do
      expect(subsystem.status).to eq(:active)
    end

    it 'defaults load to 0.0' do
      expect(subsystem.load).to eq(0.0)
    end

    it 'defaults activation_count to 0' do
      expect(subsystem.activation_count).to eq(0)
    end

    it 'defaults last_activated_at to nil' do
      expect(subsystem.last_activated_at).to be_nil
    end

    it 'sets created_at to now' do
      expect(subsystem.created_at).to be_a(Time)
    end

    it 'accepts custom health' do
      s = described_class.new(name: :s, subsystem_type: :memory, health: 0.5)
      expect(s.health).to eq(0.5)
    end

    it 'clamps health above 1.0' do
      s = described_class.new(name: :s, subsystem_type: :memory, health: 1.5)
      expect(s.health).to eq(1.0)
    end

    it 'clamps health below 0.0' do
      s = described_class.new(name: :s, subsystem_type: :memory, health: -0.5)
      expect(s.health).to eq(0.0)
    end
  end

  describe '#activate!' do
    it 'increments activation_count' do
      expect { subsystem.activate! }.to change(subsystem, :activation_count).by(1)
    end

    it 'sets last_activated_at' do
      subsystem.activate!
      expect(subsystem.last_activated_at).to be_a(Time)
    end

    it 'boosts health' do
      original = subsystem.health
      subsystem.activate!
      expect(subsystem.health).to be > original
    end

    it 'returns self for chaining' do
      expect(subsystem.activate!).to be(subsystem)
    end
  end

  describe '#degrade!' do
    it 'reduces health by HEALTH_DECAY by default' do
      original = subsystem.health
      subsystem.degrade!
      expect(subsystem.health).to be < original
    end

    it 'accepts custom amount' do
      subsystem.degrade!(0.3)
      expect(subsystem.health).to be_within(0.001).of(0.5)
    end

    it 'does not go below 0.0' do
      10.times { subsystem.degrade!(0.2) }
      expect(subsystem.health).to eq(0.0)
    end

    it 'sets status to degraded when health below 0.4' do
      subsystem.degrade!(0.5)
      expect(subsystem.status).to eq(:degraded)
    end

    it 'returns self' do
      expect(subsystem.degrade!).to be(subsystem)
    end
  end

  describe '#recover!' do
    before { subsystem.degrade!(0.5) }

    it 'boosts health' do
      original = subsystem.health
      subsystem.recover!
      expect(subsystem.health).to be > original
    end

    it 'does not exceed 1.0' do
      10.times { subsystem.recover!(0.2) }
      expect(subsystem.health).to eq(1.0)
    end

    it 'restores status to active when health reaches 0.4+' do
      subsystem.recover!(0.2)
      subsystem.recover!(0.2)
      expect(subsystem.status).to eq(:active)
    end

    it 'returns self' do
      expect(subsystem.recover!).to be(subsystem)
    end
  end

  describe '#bottlenecked?' do
    it 'returns false when load is low' do
      subsystem.load = 0.1
      expect(subsystem.bottlenecked?).to be(false)
    end

    it 'returns false when load is high but health is high' do
      subsystem.load = 0.8
      expect(subsystem.bottlenecked?).to be(false)
    end

    it 'returns true when load > BOTTLENECK_THRESHOLD and health < 0.5' do
      subsystem.load = 0.5
      subsystem.degrade!(0.4)
      expect(subsystem.bottlenecked?).to be(true)
    end
  end

  describe '#health_label' do
    it 'returns :excellent for health >= 0.8' do
      subsystem.health = 0.9
      expect(subsystem.health_label).to eq(:excellent)
    end

    it 'returns :good for health in 0.6...0.8' do
      subsystem.health = 0.7
      expect(subsystem.health_label).to eq(:good)
    end

    it 'returns :fair for health in 0.4...0.6' do
      subsystem.health = 0.5
      expect(subsystem.health_label).to eq(:fair)
    end

    it 'returns :degraded for health in 0.2...0.4' do
      subsystem.health = 0.3
      expect(subsystem.health_label).to eq(:degraded)
    end

    it 'returns :critical for health <= 0.2' do
      subsystem.health = 0.1
      expect(subsystem.health_label).to eq(:critical)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all expected keys' do
      h = subsystem.to_h
      expect(h.keys).to include(:id, :name, :subsystem_type, :health, :health_label,
                                :status, :load, :activation_count, :last_activated_at,
                                :created_at, :bottlenecked)
    end

    it 'includes bottlenecked flag' do
      expect(subsystem.to_h[:bottlenecked]).to be(false)
    end
  end
end
