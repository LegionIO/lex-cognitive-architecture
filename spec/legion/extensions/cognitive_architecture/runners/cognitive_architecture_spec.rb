# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveArchitecture::Runners::CognitiveArchitecture do
  subject(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe '#register_architecture_subsystem' do
    it 'returns registered status and subsystem hash' do
      result = runner.register_architecture_subsystem(name: :perception_hub, subsystem_type: :perception)
      expect(result[:status]).to eq(:registered)
      expect(result[:subsystem][:name]).to eq(:perception_hub)
    end

    it 'returns error status for duplicate subsystem' do
      runner.register_architecture_subsystem(name: :dup_sub, subsystem_type: :cognition)
      result = runner.register_architecture_subsystem(name: :dup_sub, subsystem_type: :memory)
      expect(result[:status]).to eq(:error)
      expect(result[:message]).to include('already registered')
    end
  end

  describe '#create_architecture_connection' do
    before do
      runner.register_architecture_subsystem(name: :src, subsystem_type: :cognition)
      runner.register_architecture_subsystem(name: :tgt, subsystem_type: :memory)
    end

    it 'returns created status and connection hash' do
      result = runner.create_architecture_connection(source_name: :src, target_name: :tgt)
      expect(result[:status]).to eq(:created)
      expect(result[:connection][:connection_type]).to eq(:informational)
    end

    it 'accepts custom connection_type and weight' do
      result = runner.create_architecture_connection(
        source_name: :src, target_name: :tgt, connection_type: :excitatory, weight: 0.9
      )
      expect(result[:connection][:connection_type]).to eq(:excitatory)
      expect(result[:connection][:weight]).to eq(0.9)
    end

    it 'returns error for unknown subsystem' do
      result = runner.create_architecture_connection(source_name: :ghost, target_name: :tgt)
      expect(result[:status]).to eq(:error)
    end
  end

  describe '#activate_architecture_subsystem' do
    before { runner.register_architecture_subsystem(name: :act_sub, subsystem_type: :cognition) }

    it 'returns activated status' do
      result = runner.activate_architecture_subsystem(name: :act_sub)
      expect(result[:status]).to eq(:activated)
    end

    it 'returns error for unknown subsystem' do
      result = runner.activate_architecture_subsystem(name: :missing)
      expect(result[:status]).to eq(:error)
    end
  end

  describe '#degrade_architecture_subsystem' do
    before { runner.register_architecture_subsystem(name: :deg_sub, subsystem_type: :safety) }

    it 'returns degraded status' do
      result = runner.degrade_architecture_subsystem(name: :deg_sub)
      expect(result[:status]).to eq(:degraded)
    end

    it 'returns error for unknown subsystem' do
      result = runner.degrade_architecture_subsystem(name: :missing)
      expect(result[:status]).to eq(:error)
    end
  end

  describe '#subsystem_status_report' do
    before { runner.register_architecture_subsystem(name: :status_sub, subsystem_type: :introspection) }

    it 'returns subsystem hash' do
      result = runner.subsystem_status_report(name: :status_sub)
      expect(result[:name]).to eq(:status_sub)
      expect(result[:subsystem_type]).to eq(:introspection)
    end

    it 'returns error hash for unknown subsystem' do
      result = runner.subsystem_status_report(name: :nope)
      expect(result[:status]).to eq(:error)
    end
  end

  describe '#bottleneck_report' do
    it 'returns a hash with bottlenecked_count and subsystems list' do
      result = runner.bottleneck_report
      expect(result).to include(:bottlenecked_count, :subsystems)
    end

    it 'returns 0 bottlenecked when subsystems are healthy' do
      runner.register_architecture_subsystem(name: :healthy_sub, subsystem_type: :cognition)
      expect(runner.bottleneck_report[:bottlenecked_count]).to eq(0)
    end
  end

  describe '#architecture_health_report' do
    it 'returns health, health_label, and active_count' do
      result = runner.architecture_health_report
      expect(result).to include(:health, :health_label, :active_count)
    end

    it 'reports 0.0 health when no subsystems' do
      expect(runner.architecture_health_report[:health]).to eq(0.0)
    end

    it 'reports correct health_label' do
      runner.register_architecture_subsystem(name: :good_sub, subsystem_type: :cognition, health: 0.9)
      result = runner.architecture_health_report
      expect(result[:health_label]).to eq(:excellent)
    end
  end

  describe '#architecture_graph_report' do
    it 'returns nodes and edges' do
      runner.register_architecture_subsystem(name: :graph_sub, subsystem_type: :coordination)
      result = runner.architecture_graph_report
      expect(result).to include(:nodes, :edges)
      expect(result[:nodes].size).to eq(1)
    end
  end

  describe '#downstream_subsystems' do
    before do
      runner.register_architecture_subsystem(name: :root, subsystem_type: :cognition)
      runner.register_architecture_subsystem(name: :child, subsystem_type: :memory)
      runner.create_architecture_connection(source_name: :root, target_name: :child)
    end

    it 'returns reachable subsystems' do
      result = runner.downstream_subsystems(name: :root)
      names = result[:reachable].map { |s| s[:name] }
      expect(names).to include(:child)
    end

    it 'returns count of reachable' do
      result = runner.downstream_subsystems(name: :root)
      expect(result[:count]).to eq(1)
    end

    it 'returns error for unknown source' do
      result = runner.downstream_subsystems(name: :ghost)
      expect(result[:status]).to eq(:error)
    end
  end

  describe '#update_cognitive_architecture' do
    it 'returns updated status' do
      result = runner.update_cognitive_architecture
      expect(result[:status]).to eq(:updated)
      expect(result).to include(:decayed)
    end

    it 'decays subsystems health' do
      runner.register_architecture_subsystem(name: :decay_sub, subsystem_type: :cognition)
      before_health = runner.subsystem_status_report(name: :decay_sub)[:health]
      runner.update_cognitive_architecture
      after_health = runner.subsystem_status_report(name: :decay_sub)[:health]
      expect(after_health).to be < before_health
    end
  end

  describe '#cognitive_architecture_stats' do
    it 'returns summary stats' do
      runner.register_architecture_subsystem(name: :stats_sub, subsystem_type: :coordination)
      result = runner.cognitive_architecture_stats
      expect(result).to include(:subsystem_count, :connection_count, :active_count,
                                :bottlenecked_count, :architecture_health)
      expect(result[:subsystem_count]).to eq(1)
    end
  end
end
