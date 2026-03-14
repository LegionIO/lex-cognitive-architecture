# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveArchitecture
      module Helpers
        class ArchitectureEngine
          include Constants

          def initialize
            @subsystems  = {}
            @connections = {}
          end

          def register_subsystem(name:, subsystem_type:, health: Constants::DEFAULT_HEALTH)
            raise ArgumentError, "subsystem '#{name}' already registered" if @subsystems.key?(name.to_sym)
            raise ArgumentError, "max subsystems (#{Constants::MAX_SUBSYSTEMS}) reached" if @subsystems.size >= Constants::MAX_SUBSYSTEMS

            subsystem = Subsystem.new(name: name, subsystem_type: subsystem_type, health: health)
            @subsystems[subsystem.name] = subsystem
            subsystem
          end

          def create_connection(source_name:, target_name:, connection_type: :informational, weight: 0.5)
            raise ArgumentError, "max connections (#{Constants::MAX_CONNECTIONS}) reached" if @connections.size >= Constants::MAX_CONNECTIONS

            source = find_subsystem!(source_name)
            target = find_subsystem!(target_name)

            conn = Connection.new(
              source_id:       source.id,
              target_id:       target.id,
              connection_type: connection_type,
              weight:          weight
            )
            @connections[conn.id] = conn
            conn
          end

          def activate_subsystem(name:)
            subsystem = find_subsystem!(name)
            subsystem.activate!

            excitatory_connections_from(subsystem.id).each do |conn|
              target = subsystem_by_id(conn.target_id)
              target&.activate!
            end

            { name: subsystem.name, status: subsystem.status, health: subsystem.health }
          end

          def degrade_subsystem(name:)
            subsystem = find_subsystem!(name)
            subsystem.degrade!
            { name: subsystem.name, status: subsystem.status, health: subsystem.health }
          end

          def recover_subsystem(name:)
            subsystem = find_subsystem!(name)
            subsystem.recover!
            { name: subsystem.name, status: subsystem.status, health: subsystem.health }
          end

          def subsystem_status(name:)
            find_subsystem!(name).to_h
          end

          def active_subsystems
            @subsystems.values.select { |s| s.status == :active }
          end

          def bottlenecked_subsystems
            @subsystems.values.select(&:bottlenecked?)
          end

          def connections_for(name:)
            subsystem = find_subsystem!(name)
            @connections.values.select do |c|
              c.source_id == subsystem.id || c.target_id == subsystem.id
            end
          end

          def downstream(name:, max_depth: 5)
            start   = find_subsystem!(name)
            visited = bfs_visited(start.id, max_depth)
            visited.keys.filter_map { |sid| subsystem_by_id(sid) }.reject { |s| s.id == start.id }
          end

          def architecture_health
            return 0.0 if @subsystems.empty?

            total = @subsystems.values.sum(&:health)
            total / @subsystems.size
          end

          def architecture_graph
            {
              nodes: @subsystems.values.map(&:to_h),
              edges: @connections.values.map(&:to_h)
            }
          end

          def decay_all
            @subsystems.each_value { |s| s.degrade!(Constants::HEALTH_DECAY) }
            { decayed: @subsystems.size }
          end

          def to_h
            {
              subsystem_count:     @subsystems.size,
              connection_count:    @connections.size,
              active_count:        active_subsystems.size,
              bottlenecked_count:  bottlenecked_subsystems.size,
              architecture_health: architecture_health
            }
          end

          private

          def find_subsystem!(name)
            @subsystems.fetch(name.to_sym) do
              raise ArgumentError, "subsystem '#{name}' not found"
            end
          end

          def subsystem_by_id(id)
            @subsystems.values.find { |s| s.id == id }
          end

          def excitatory_connections_from(source_id)
            @connections.values.select do |c|
              c.source_id == source_id && c.connection_type == :excitatory && c.active
            end
          end

          def bfs_visited(start_id, max_depth)
            visited = {}
            queue   = [[start_id, 0]]

            until queue.empty?
              current_id, depth = queue.shift
              next if visited.key?(current_id)

              visited[current_id] = depth
              enqueue_neighbors(current_id, depth, visited, queue) if depth < max_depth
            end

            visited
          end

          def enqueue_neighbors(current_id, depth, visited, queue)
            @connections.each_value do |conn|
              next unless conn.source_id == current_id && conn.active
              next if visited.key?(conn.target_id)

              queue << [conn.target_id, depth + 1]
            end
          end
        end
      end
    end
  end
end
