# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveArchitecture
      class Client
        include Runners::CognitiveArchitecture

        def initialize(**)
          @engine = Helpers::ArchitectureEngine.new
        end
      end
    end
  end
end
