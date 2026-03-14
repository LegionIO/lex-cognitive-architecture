# lex-cognitive-architecture

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Meta-extension that models the agent cognitive architecture as a graph of subsystems, connections, and information flows — enabling self-awareness of its own architecture. Provides health monitoring, bottleneck detection, and downstream traversal across named subsystems.

## Gem Info

- **Gem name**: `lex-cognitive-architecture`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::CognitiveArchitecture`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/cognitive_architecture/
  cognitive_architecture.rb        # top-level require
  version.rb
  client.rb
  helpers/
    constants.rb
    subsystem.rb
    connection.rb
    architecture_engine.rb
  runners/
    cognitive_architecture.rb
```

## Key Constants

From `helpers/constants.rb`:

- `SUBSYSTEM_TYPES` — `%i[perception cognition memory motivation safety communication introspection coordination]`
- `CONNECTION_TYPES` — `%i[excitatory inhibitory modulatory informational]`
- `STATUS_LEVELS` — `%i[active idle degraded offline]`
- `HEALTH_LABELS` — range map: `0.8+` = `:excellent`, `0.6` = `:good`, `0.4` = `:fair`, `0.2` = `:degraded`, below = `:critical`
- `BOTTLENECK_THRESHOLD` = `0.3` (load > threshold AND health < 0.5)
- `MAX_SUBSYSTEMS` = `200`, `MAX_CONNECTIONS` = `1000`, `MAX_HISTORY` = `500`
- `DEFAULT_HEALTH` = `0.8`, `HEALTH_DECAY` = `0.01`, `HEALTH_BOOST` = `0.05`

## Runners

All methods in `Runners::CognitiveArchitecture` (`extend self`):

- `register_architecture_subsystem(name:, subsystem_type:, health: DEFAULT_HEALTH)` — registers a new named subsystem; raises on duplicate or capacity exceeded
- `create_architecture_connection(source_name:, target_name:, connection_type: :informational, weight: 0.5)` — creates a directed connection between two subsystems
- `activate_architecture_subsystem(name:)` — activates subsystem and propagates activation to excitatory targets
- `degrade_architecture_subsystem(name:)` — applies health decay; marks `:degraded` when health < 0.4
- `subsystem_status_report(name:)` — returns full `to_h` for a named subsystem
- `bottleneck_report` — returns all subsystems where load > 0.3 AND health < 0.5
- `architecture_health_report` — average health across all subsystems + active count
- `architecture_graph_report` — full `{ nodes:, edges: }` graph
- `downstream_subsystems(name:, max_depth: 5)` — BFS traversal of reachable subsystems
- `update_cognitive_architecture` — runs `decay_all` (decrements health by `HEALTH_DECAY` on all)
- `cognitive_architecture_stats` — summary hash: counts, health, bottleneck count

## Helpers

- `ArchitectureEngine` — in-memory store of `Subsystem` and `Connection` objects. BFS traversal via `downstream`. Excitatory connections propagate activation.
- `Subsystem` — has `id`, `name`, `subsystem_type`, `health`, `status`, `load`, `activation_count`. Methods: `activate!`, `degrade!(amount)`, `recover!(amount)`, `bottlenecked?`, `health_label`.
- `Connection` — directed edge with `source_id`, `target_id`, `connection_type`, `weight`, `active`. Methods: `strengthen!`, `weaken!`, `toggle!`.

## Integration Points

- No direct dependencies on other agentic LEXs. This extension is a meta-layer: any other extension can register its processing subsystem here to make the architecture graph self-aware.
- `lex-cortex` is the natural caller: wiring `lex-cognitive-architecture` into the tick cycle allows the agent to model its own cognitive topology during introspection phases.
- `activate_architecture_subsystem` propagates through excitatory connections, modeling cascading activation across cognitive subsystems.

## Development Notes

- `ArchitectureEngine` state is per-`RunnerHost` instance (in-memory only; resets on restart).
- `decay_all` runs `degrade!(HEALTH_DECAY)` on every subsystem — intended to be called periodically (e.g., `update_cognitive_architecture` runner).
- Subsystem names are coerced to symbols on registration; duplicate names raise `ArgumentError`.
- Bottleneck detection requires both high load (`@load > BOTTLENECK_THRESHOLD`) and low health (`@health < 0.5`). `@load` is set externally — the engine does not auto-compute it.
- BFS depth limit (`max_depth: 5`) prevents runaway traversal in dense graphs.
