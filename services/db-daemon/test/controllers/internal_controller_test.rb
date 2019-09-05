# frozen_string_literal: true

require 'test_helper'

class InternalControllerTest < ActionDispatch::IntegrationTest
  test 'should get metrics' do
    get internal_metrics_url
    assert_response :success
  end

  test 'should get healthz' do
    get internal_healthz_url
    assert_response :success
  end
end
