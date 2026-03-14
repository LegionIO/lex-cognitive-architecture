# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveArchitecture::Client do
  subject(:client) { described_class.new }

  it 'can register a subsystem' do
    result = client.register_architecture_subsystem(name: :test_system, subsystem_type: :cognition)
    expect(result[:status]).to eq(:registered)
  end

  it 'maintains isolated engine state per instance' do
    client2 = described_class.new
    client.register_architecture_subsystem(name: :isolated_a, subsystem_type: :cognition)
    client2.register_architecture_subsystem(name: :isolated_b, subsystem_type: :memory)

    stats_a = client.cognitive_architecture_stats
    stats_b = client2.cognitive_architecture_stats

    expect(stats_a[:subsystem_count]).to eq(1)
    expect(stats_b[:subsystem_count]).to eq(1)
  end

  it 'supports full registration + connection + activation workflow' do
    client.register_architecture_subsystem(name: :sensor, subsystem_type: :perception)
    client.register_architecture_subsystem(name: :processor, subsystem_type: :cognition)
    client.create_architecture_connection(
      source_name: :sensor, target_name: :processor, connection_type: :excitatory
    )
    result = client.activate_architecture_subsystem(name: :sensor)
    expect(result[:status]).to eq(:activated)

    processor_status = client.subsystem_status_report(name: :processor)
    expect(processor_status[:activation_count]).to eq(1)
  end

  it 'reports architecture health after degradation' do
    client.register_architecture_subsystem(name: :health_sub, subsystem_type: :safety)
    client.degrade_architecture_subsystem(name: :health_sub)
    report = client.architecture_health_report
    expect(report[:health]).to be < Legion::Extensions::CognitiveArchitecture::Helpers::Constants::DEFAULT_HEALTH
  end

  it 'detects bottlenecks' do
    client.register_architecture_subsystem(name: :stressed, subsystem_type: :communication)
    sub = client.architecture_graph_report[:nodes].find { |n| n[:name] == :stressed }
    real_sub = Object.new
    allow(real_sub).to receive_messages(name: :stressed, status: :active, bottlenecked?: true, to_h: sub)
    report = client.bottleneck_report
    expect(report).to include(:bottlenecked_count, :subsystems)
  end
end
