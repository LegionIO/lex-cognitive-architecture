# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveArchitecture::Helpers::ArchitectureEngine do
  subject(:engine) { described_class.new }

  let(:constants) { Legion::Extensions::CognitiveArchitecture::Helpers::Constants }

  def register_pair
    engine.register_subsystem(name: :source, subsystem_type: :cognition)
    engine.register_subsystem(name: :target, subsystem_type: :memory)
  end

  describe '#register_subsystem' do
    it 'returns a Subsystem instance' do
      result = engine.register_subsystem(name: :cognition_hub, subsystem_type: :cognition)
      expect(result).to be_a(Legion::Extensions::CognitiveArchitecture::Helpers::Subsystem)
    end

    it 'stores the subsystem by name' do
      engine.register_subsystem(name: :my_sub, subsystem_type: :memory)
      expect(engine.active_subsystems.map(&:name)).to include(:my_sub)
    end

    it 'raises on duplicate name' do
      engine.register_subsystem(name: :dup, subsystem_type: :cognition)
      expect { engine.register_subsystem(name: :dup, subsystem_type: :memory) }
        .to raise_error(ArgumentError, /already registered/)
    end

    it 'accepts custom health' do
      sub = engine.register_subsystem(name: :custom, subsystem_type: :safety, health: 0.5)
      expect(sub.health).to eq(0.5)
    end
  end

  describe '#create_connection' do
    before { register_pair }

    it 'returns a Connection instance' do
      conn = engine.create_connection(source_name: :source, target_name: :target)
      expect(conn).to be_a(Legion::Extensions::CognitiveArchitecture::Helpers::Connection)
    end

    it 'links source and target by id' do
      source_id = engine.subsystem_status(name: :source)[:id]
      target_id = engine.subsystem_status(name: :target)[:id]
      conn = engine.create_connection(source_name: :source, target_name: :target)
      expect(conn.source_id).to eq(source_id)
      expect(conn.target_id).to eq(target_id)
    end

    it 'raises when source does not exist' do
      expect { engine.create_connection(source_name: :ghost, target_name: :target) }
        .to raise_error(ArgumentError, /not found/)
    end

    it 'accepts custom connection_type and weight' do
      conn = engine.create_connection(
        source_name: :source, target_name: :target, connection_type: :excitatory, weight: 0.9
      )
      expect(conn.connection_type).to eq(:excitatory)
      expect(conn.weight).to eq(0.9)
    end
  end

  describe '#activate_subsystem' do
    before { register_pair }

    it 'returns a result hash' do
      result = engine.activate_subsystem(name: :source)
      expect(result).to include(:name, :status, :health)
    end

    it 'increments activation_count on the subsystem' do
      engine.activate_subsystem(name: :source)
      status = engine.subsystem_status(name: :source)
      expect(status[:activation_count]).to eq(1)
    end

    it 'propagates activation to excitatory neighbors' do
      engine.create_connection(source_name: :source, target_name: :target, connection_type: :excitatory)
      engine.activate_subsystem(name: :source)
      target_status = engine.subsystem_status(name: :target)
      expect(target_status[:activation_count]).to eq(1)
    end

    it 'does not propagate for non-excitatory connections' do
      engine.create_connection(source_name: :source, target_name: :target, connection_type: :inhibitory)
      engine.activate_subsystem(name: :source)
      target_status = engine.subsystem_status(name: :target)
      expect(target_status[:activation_count]).to eq(0)
    end

    it 'does not propagate via inactive connections' do
      conn = engine.create_connection(source_name: :source, target_name: :target, connection_type: :excitatory)
      conn.toggle!
      engine.activate_subsystem(name: :source)
      target_status = engine.subsystem_status(name: :target)
      expect(target_status[:activation_count]).to eq(0)
    end

    it 'raises for unknown subsystem' do
      expect { engine.activate_subsystem(name: :unknown) }.to raise_error(ArgumentError)
    end
  end

  describe '#degrade_subsystem' do
    before { engine.register_subsystem(name: :deg_sub, subsystem_type: :cognition) }

    it 'reduces health' do
      original = engine.subsystem_status(name: :deg_sub)[:health]
      engine.degrade_subsystem(name: :deg_sub)
      expect(engine.subsystem_status(name: :deg_sub)[:health]).to be < original
    end

    it 'returns a hash with name and health' do
      result = engine.degrade_subsystem(name: :deg_sub)
      expect(result).to include(:name, :health, :status)
    end
  end

  describe '#recover_subsystem' do
    before do
      engine.register_subsystem(name: :rec_sub, subsystem_type: :cognition)
      engine.degrade_subsystem(name: :rec_sub)
    end

    it 'increases health' do
      before_health = engine.subsystem_status(name: :rec_sub)[:health]
      engine.recover_subsystem(name: :rec_sub)
      expect(engine.subsystem_status(name: :rec_sub)[:health]).to be > before_health
    end
  end

  describe '#subsystem_status' do
    before { engine.register_subsystem(name: :status_sub, subsystem_type: :introspection) }

    it 'returns a full status hash' do
      h = engine.subsystem_status(name: :status_sub)
      expect(h[:name]).to eq(:status_sub)
      expect(h[:subsystem_type]).to eq(:introspection)
    end

    it 'raises for unknown subsystem' do
      expect { engine.subsystem_status(name: :nope) }.to raise_error(ArgumentError)
    end
  end

  describe '#active_subsystems' do
    it 'returns only active subsystems' do
      engine.register_subsystem(name: :active_one, subsystem_type: :cognition)
      engine.register_subsystem(name: :inactive_one, subsystem_type: :memory)
      engine.degrade_subsystem(name: :inactive_one)
      engine.degrade_subsystem(name: :inactive_one)
      engine.degrade_subsystem(name: :inactive_one)
      engine.degrade_subsystem(name: :inactive_one)
      engine.degrade_subsystem(name: :inactive_one)

      names = engine.active_subsystems.map(&:name)
      expect(names).to include(:active_one)
    end

    it 'returns empty array when no subsystems' do
      expect(engine.active_subsystems).to be_empty
    end
  end

  describe '#bottlenecked_subsystems' do
    it 'returns subsystems that are bottlenecked' do
      engine.register_subsystem(name: :bottleneck, subsystem_type: :communication)
      sub = engine.active_subsystems.find { |s| s.name == :bottleneck }
      sub.load = 0.5
      sub.health = 0.3

      result = engine.bottlenecked_subsystems
      expect(result.map(&:name)).to include(:bottleneck)
    end

    it 'excludes healthy subsystems' do
      engine.register_subsystem(name: :healthy, subsystem_type: :cognition)
      expect(engine.bottlenecked_subsystems).to be_empty
    end
  end

  describe '#connections_for' do
    before { register_pair }

    it 'returns connections involving the subsystem' do
      engine.create_connection(source_name: :source, target_name: :target)
      conns = engine.connections_for(name: :source)
      expect(conns).not_to be_empty
    end

    it 'includes connections where subsystem is the target' do
      engine.create_connection(source_name: :source, target_name: :target)
      conns = engine.connections_for(name: :target)
      expect(conns).not_to be_empty
    end

    it 'returns empty when no connections' do
      engine.register_subsystem(name: :isolated, subsystem_type: :safety)
      expect(engine.connections_for(name: :isolated)).to be_empty
    end
  end

  describe '#downstream' do
    before do
      engine.register_subsystem(name: :a, subsystem_type: :cognition)
      engine.register_subsystem(name: :b, subsystem_type: :memory)
      engine.register_subsystem(name: :c, subsystem_type: :motivation)
      engine.register_subsystem(name: :d, subsystem_type: :safety)
    end

    it 'returns direct downstream neighbors' do
      engine.create_connection(source_name: :a, target_name: :b)
      result = engine.downstream(name: :a)
      expect(result.map(&:name)).to include(:b)
    end

    it 'traverses multi-hop paths' do
      engine.create_connection(source_name: :a, target_name: :b)
      engine.create_connection(source_name: :b, target_name: :c)
      result = engine.downstream(name: :a)
      names = result.map(&:name)
      expect(names).to include(:b, :c)
    end

    it 'does not include the source subsystem itself' do
      engine.create_connection(source_name: :a, target_name: :b)
      result = engine.downstream(name: :a)
      expect(result.map(&:name)).not_to include(:a)
    end

    it 'respects max_depth limit' do
      engine.create_connection(source_name: :a, target_name: :b)
      engine.create_connection(source_name: :b, target_name: :c)
      engine.create_connection(source_name: :c, target_name: :d)
      result = engine.downstream(name: :a, max_depth: 1)
      expect(result.map(&:name)).to include(:b)
      expect(result.map(&:name)).not_to include(:c)
    end

    it 'handles cycles without infinite loop' do
      engine.create_connection(source_name: :a, target_name: :b)
      engine.create_connection(source_name: :b, target_name: :a)
      expect { engine.downstream(name: :a) }.not_to raise_error
    end

    it 'skips inactive connections' do
      conn = engine.create_connection(source_name: :a, target_name: :b)
      conn.toggle!
      result = engine.downstream(name: :a)
      expect(result.map(&:name)).not_to include(:b)
    end
  end

  describe '#architecture_health' do
    it 'returns 0.0 when no subsystems' do
      expect(engine.architecture_health).to eq(0.0)
    end

    it 'returns average health across all subsystems' do
      engine.register_subsystem(name: :s1, subsystem_type: :cognition, health: 1.0)
      engine.register_subsystem(name: :s2, subsystem_type: :memory, health: 0.5)
      expect(engine.architecture_health).to be_within(0.001).of(0.75)
    end
  end

  describe '#architecture_graph' do
    before { register_pair }

    it 'returns hash with nodes and edges keys' do
      engine.create_connection(source_name: :source, target_name: :target)
      graph = engine.architecture_graph
      expect(graph).to include(:nodes, :edges)
    end

    it 'nodes contains subsystem hashes' do
      graph = engine.architecture_graph
      names = graph[:nodes].map { |n| n[:name] }
      expect(names).to include(:source, :target)
    end

    it 'edges contains connection hashes' do
      engine.create_connection(source_name: :source, target_name: :target)
      graph = engine.architecture_graph
      expect(graph[:edges]).not_to be_empty
    end
  end

  describe '#decay_all' do
    it 'degrades all subsystems' do
      engine.register_subsystem(name: :d1, subsystem_type: :cognition)
      engine.register_subsystem(name: :d2, subsystem_type: :memory)
      health_before = engine.architecture_health
      engine.decay_all
      expect(engine.architecture_health).to be < health_before
    end

    it 'returns decayed count' do
      engine.register_subsystem(name: :dec, subsystem_type: :cognition)
      result = engine.decay_all
      expect(result[:decayed]).to eq(1)
    end
  end

  describe '#to_h' do
    it 'returns summary stats hash' do
      engine.register_subsystem(name: :stat_sub, subsystem_type: :coordination)
      h = engine.to_h
      expect(h).to include(:subsystem_count, :connection_count, :active_count,
                           :bottlenecked_count, :architecture_health)
    end

    it 'reports correct subsystem_count' do
      engine.register_subsystem(name: :s1, subsystem_type: :cognition)
      engine.register_subsystem(name: :s2, subsystem_type: :memory)
      expect(engine.to_h[:subsystem_count]).to eq(2)
    end
  end
end
