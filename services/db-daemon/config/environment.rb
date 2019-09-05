# frozen_string_literal: true

require 'dotenv'
Dotenv.load '.env'

require 'benchmark'

# Load the Rails application.
require_relative 'application'

# Load custom errors and exceptions
require 'local_errors'

# Initialize the Rails application.
Rails.application.initialize!
