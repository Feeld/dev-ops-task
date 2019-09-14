# frozen_string_literal: true

unless ENV['RAILS_ENV'] == 'production'
  require 'dotenv'
  Dotenv.load '.env'
end

require 'benchmark'

# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!
