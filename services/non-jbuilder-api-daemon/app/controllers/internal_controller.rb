# frozen_string_literal: true

class InternalController < ApplicationController
  def metrics; end

  def healthz; end
end
