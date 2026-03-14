# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveArchitecture
      module Helpers
        module Constants
          SUBSYSTEM_TYPES  = %i[perception cognition memory motivation safety communication introspection coordination].freeze
          CONNECTION_TYPES = %i[excitatory inhibitory modulatory informational].freeze
          STATUS_LEVELS    = %i[active idle degraded offline].freeze

          HEALTH_LABELS = {
            (0.8..)     => :excellent,
            (0.6...0.8) => :good,
            (0.4...0.6) => :fair,
            (0.2...0.4) => :degraded,
            (..0.2)     => :critical
          }.freeze

          BOTTLENECK_THRESHOLD = 0.3

          MAX_SUBSYSTEMS  = 200
          MAX_CONNECTIONS = 1000
          MAX_HISTORY     = 500

          DEFAULT_HEALTH = 0.8
          HEALTH_DECAY   = 0.01
          HEALTH_BOOST   = 0.05
        end
      end
    end
  end
end
