# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveArchitecture
      module Helpers
        class Connection
          attr_reader :id, :source_id, :target_id, :connection_type, :created_at
          attr_accessor :weight, :active

          def initialize(source_id:, target_id:, connection_type: :informational, weight: 0.5)
            @id              = SecureRandom.uuid
            @source_id       = source_id
            @target_id       = target_id
            @connection_type = connection_type.to_sym
            @weight          = weight.clamp(0.0, 1.0)
            @active          = true
            @created_at      = Time.now.utc
          end

          def strengthen!(amount = 0.05)
            @weight = (@weight + amount).clamp(0.0, 1.0)
            self
          end

          def weaken!(amount = 0.05)
            @weight = (@weight - amount).clamp(0.0, 1.0)
            self
          end

          def toggle!
            @active = !@active
            self
          end

          def to_h
            {
              id:              @id,
              source_id:       @source_id,
              target_id:       @target_id,
              connection_type: @connection_type,
              weight:          @weight,
              active:          @active,
              created_at:      @created_at
            }
          end
        end
      end
    end
  end
end
