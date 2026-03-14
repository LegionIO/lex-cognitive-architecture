# lex-cognitive-architecture

Meta-extension that models the agent cognitive architecture as a graph of subsystems, connections, and information flows — enabling self-awareness of its own architecture.

## What It Does

Provides a self-model of the agent's cognitive topology. Subsystems (perception, memory, motivation, safety, etc.) are registered as graph nodes with health scores and load tracking. Directed connections between subsystems have types (excitatory, inhibitory, modulatory, informational) and weights. The engine supports:

- Health decay and activation propagation across connected subsystems
- Bottleneck detection (high load + low health)
- BFS downstream traversal to find all reachable subsystems from a source
- Architecture-wide health scoring and graph export

## Usage

```ruby
client = Legion::Extensions::CognitiveArchitecture::Client.new

client.register_architecture_subsystem(name: :memory, subsystem_type: :memory)
client.register_architecture_subsystem(name: :emotion, subsystem_type: :cognition)
client.create_architecture_connection(
  source_name: :emotion,
  target_name: :memory,
  connection_type: :excitatory,
  weight: 0.8
)

client.activate_architecture_subsystem(name: :emotion)
client.architecture_health_report
client.bottleneck_report
client.architecture_graph_report
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
