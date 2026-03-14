# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveArchitecture
      module Runners
        module CognitiveArchitecture
          extend self

          def register_architecture_subsystem(name:, subsystem_type:, health: Helpers::Constants::DEFAULT_HEALTH, **)
            Legion::Logging.debug "[cognitive_architecture] registering subsystem: #{name} (#{subsystem_type})"
            subsystem = engine.register_subsystem(name: name, subsystem_type: subsystem_type, health: health)
            { status: :registered, subsystem: subsystem.to_h }
          rescue ArgumentError => e
            Legion::Logging.warn "[cognitive_architecture] register_subsystem failed: #{e.message}"
            { status: :error, message: e.message }
          end

          def create_architecture_connection(source_name:, target_name:,
                                             connection_type: :informational, weight: 0.5, **)
            Legion::Logging.debug "[cognitive_architecture] creating connection: #{source_name} -> #{target_name} (#{connection_type})"
            conn = engine.create_connection(
              source_name:     source_name,
              target_name:     target_name,
              connection_type: connection_type,
              weight:          weight
            )
            { status: :created, connection: conn.to_h }
          rescue ArgumentError => e
            Legion::Logging.warn "[cognitive_architecture] create_connection failed: #{e.message}"
            { status: :error, message: e.message }
          end

          def activate_architecture_subsystem(name:, **)
            Legion::Logging.debug "[cognitive_architecture] activating subsystem: #{name}"
            result = engine.activate_subsystem(name: name)
            { status: :activated, name: result[:name], health: result[:health], subsystem_status: result[:status] }
          rescue ArgumentError => e
            Legion::Logging.warn "[cognitive_architecture] activate_subsystem failed: #{e.message}"
            { status: :error, message: e.message }
          end

          def degrade_architecture_subsystem(name:, **)
            Legion::Logging.debug "[cognitive_architecture] degrading subsystem: #{name}"
            result = engine.degrade_subsystem(name: name)
            { status: :degraded, name: result[:name], health: result[:health], subsystem_status: result[:status] }
          rescue ArgumentError => e
            Legion::Logging.warn "[cognitive_architecture] degrade_subsystem failed: #{e.message}"
            { status: :error, message: e.message }
          end

          def subsystem_status_report(name:, **)
            Legion::Logging.debug "[cognitive_architecture] status report for: #{name}"
            engine.subsystem_status(name: name)
          rescue ArgumentError => e
            { status: :error, message: e.message }
          end

          def bottleneck_report(**)
            bottlenecked = engine.bottlenecked_subsystems
            Legion::Logging.debug "[cognitive_architecture] bottleneck_report: #{bottlenecked.size} bottlenecked"
            {
              bottlenecked_count: bottlenecked.size,
              subsystems:         bottlenecked.map(&:to_h)
            }
          end

          def architecture_health_report(**)
            health = engine.architecture_health
            Legion::Logging.debug "[cognitive_architecture] architecture_health: #{health.round(3)}"
            {
              health:       health,
              health_label: label_for_health(health),
              active_count: engine.active_subsystems.size
            }
          end

          def architecture_graph_report(**)
            Legion::Logging.debug '[cognitive_architecture] building architecture_graph'
            engine.architecture_graph
          end

          def downstream_subsystems(name:, max_depth: 5, **)
            Legion::Logging.debug "[cognitive_architecture] downstream traversal from: #{name} (max_depth=#{max_depth})"
            reachable = engine.downstream(name: name, max_depth: max_depth)
            {
              source:    name,
              reachable: reachable.map(&:to_h),
              count:     reachable.size
            }
          rescue ArgumentError => e
            { status: :error, message: e.message }
          end

          def update_cognitive_architecture(**)
            Legion::Logging.debug '[cognitive_architecture] running decay cycle'
            result = engine.decay_all
            { status: :updated, decayed: result[:decayed] }
          end

          def cognitive_architecture_stats(**)
            engine.to_h
          end

          private

          def engine
            @engine ||= Helpers::ArchitectureEngine.new
          end

          def label_for_health(health)
            Helpers::Constants::HEALTH_LABELS.each do |range, label|
              return label if range.cover?(health)
            end
            :critical
          end
        end
      end
    end
  end
end
