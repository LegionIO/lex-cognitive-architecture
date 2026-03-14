# frozen_string_literal: true

require 'legion/extensions/cognitive_architecture/version'
require 'legion/extensions/cognitive_architecture/helpers/constants'
require 'legion/extensions/cognitive_architecture/helpers/subsystem'
require 'legion/extensions/cognitive_architecture/helpers/connection'
require 'legion/extensions/cognitive_architecture/helpers/architecture_engine'
require 'legion/extensions/cognitive_architecture/runners/cognitive_architecture'
require 'legion/extensions/cognitive_architecture/client'

module Legion
  module Extensions
    module CognitiveArchitecture
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
