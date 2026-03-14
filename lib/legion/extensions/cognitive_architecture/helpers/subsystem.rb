# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveArchitecture
      module Helpers
        class Subsystem
          include Constants

          attr_reader :id, :name, :subsystem_type, :activation_count, :last_activated_at, :created_at
          attr_accessor :health, :status, :load

          def initialize(name:, subsystem_type:, health: Constants::DEFAULT_HEALTH)
            @id               = SecureRandom.uuid
            @name             = name.to_sym
            @subsystem_type   = subsystem_type.to_sym
            @health           = health.clamp(0.0, 1.0)
            @status           = :active
            @load             = 0.0
            @activation_count = 0
            @last_activated_at = nil
            @created_at       = Time.now.utc
          end

          def activate!
            @activation_count += 1
            @last_activated_at = Time.now.utc
            @health = (@health + Constants::HEALTH_BOOST).clamp(0.0, 1.0)
            self
          end

          def degrade!(amount = Constants::HEALTH_DECAY)
            @health = (@health - amount).clamp(0.0, 1.0)
            @status = :degraded if @health < 0.4
            self
          end

          def recover!(amount = Constants::HEALTH_BOOST)
            @health = (@health + amount).clamp(0.0, 1.0)
            @status = :active if @health >= 0.4
            self
          end

          def bottlenecked?
            @load > Constants::BOTTLENECK_THRESHOLD && @health < 0.5
          end

          def health_label
            Constants::HEALTH_LABELS.each do |range, label|
              return label if range.cover?(@health)
            end
            :critical
          end

          def to_h
            {
              id:                @id,
              name:              @name,
              subsystem_type:    @subsystem_type,
              health:            @health,
              health_label:      health_label,
              status:            @status,
              load:              @load,
              activation_count:  @activation_count,
              last_activated_at: @last_activated_at,
              created_at:        @created_at,
              bottlenecked:      bottlenecked?
            }
          end
        end
      end
    end
  end
end
