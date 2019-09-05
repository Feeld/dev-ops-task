# frozen_string_literal: true

require 'test_helper'

class LogEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @log_entry = log_entries(:one)
  end

  test 'should get index' do
    get log_entries_url, as: :json
    assert_response :success
  end

  test 'should create log_entry' do
    assert_difference('LogEntry.count') do
      post log_entries_url, params: { log_entry: { details: @log_entry.details, failing: @log_entry.failing, message_id: @log_entry.message_id } }, as: :json
    end

    assert_response 201
  end

  test 'should show log_entry' do
    get log_entry_url(@log_entry), as: :json
    assert_response :success
  end

  test 'should update log_entry' do
    patch log_entry_url(@log_entry), params: { log_entry: { details: @log_entry.details, failing: @log_entry.failing, message_id: @log_entry.message_id } }, as: :json
    assert_response 200
  end

  test 'should destroy log_entry' do
    assert_difference('LogEntry.count', -1) do
      delete log_entry_url(@log_entry), as: :json
    end

    assert_response 204
  end
end
