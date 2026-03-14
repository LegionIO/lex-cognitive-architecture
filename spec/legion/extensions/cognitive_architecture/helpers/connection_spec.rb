# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveArchitecture::Helpers::Connection do
  subject(:connection) do
    described_class.new(source_id: 'src-uuid', target_id: 'tgt-uuid')
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(connection.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores source_id' do
      expect(connection.source_id).to eq('src-uuid')
    end

    it 'stores target_id' do
      expect(connection.target_id).to eq('tgt-uuid')
    end

    it 'defaults connection_type to :informational' do
      expect(connection.connection_type).to eq(:informational)
    end

    it 'defaults weight to 0.5' do
      expect(connection.weight).to eq(0.5)
    end

    it 'defaults active to true' do
      expect(connection.active).to be(true)
    end

    it 'sets created_at to now' do
      expect(connection.created_at).to be_a(Time)
    end

    it 'accepts custom connection_type' do
      c = described_class.new(source_id: 's', target_id: 't', connection_type: :excitatory)
      expect(c.connection_type).to eq(:excitatory)
    end

    it 'clamps weight above 1.0' do
      c = described_class.new(source_id: 's', target_id: 't', weight: 1.5)
      expect(c.weight).to eq(1.0)
    end

    it 'clamps weight below 0.0' do
      c = described_class.new(source_id: 's', target_id: 't', weight: -0.5)
      expect(c.weight).to eq(0.0)
    end
  end

  describe '#strengthen!' do
    it 'increases weight by 0.05 by default' do
      before_weight = connection.weight
      connection.strengthen!
      expect(connection.weight).to be_within(0.001).of(before_weight + 0.05)
    end

    it 'does not exceed 1.0' do
      connection.weight = 0.98
      connection.strengthen!
      expect(connection.weight).to eq(1.0)
    end

    it 'returns self' do
      expect(connection.strengthen!).to be(connection)
    end
  end

  describe '#weaken!' do
    it 'decreases weight by 0.05 by default' do
      before_weight = connection.weight
      connection.weaken!
      expect(connection.weight).to be_within(0.001).of(before_weight - 0.05)
    end

    it 'does not go below 0.0' do
      connection.weight = 0.02
      connection.weaken!
      expect(connection.weight).to eq(0.0)
    end

    it 'returns self' do
      expect(connection.weaken!).to be(connection)
    end
  end

  describe '#toggle!' do
    it 'flips active from true to false' do
      expect { connection.toggle! }.to change(connection, :active).from(true).to(false)
    end

    it 'flips active from false to true' do
      connection.active = false
      expect { connection.toggle! }.to change(connection, :active).from(false).to(true)
    end

    it 'returns self' do
      expect(connection.toggle!).to be(connection)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all expected keys' do
      h = connection.to_h
      expect(h.keys).to include(:id, :source_id, :target_id, :connection_type, :weight, :active, :created_at)
    end

    it 'reflects current state' do
      connection.weight = 0.8
      connection.active = false
      h = connection.to_h
      expect(h[:weight]).to eq(0.8)
      expect(h[:active]).to be(false)
    end
  end
end
