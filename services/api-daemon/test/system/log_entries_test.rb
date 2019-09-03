require "application_system_test_case"

class LogEntriesTest < ApplicationSystemTestCase
  setup do
    @log_entry = log_entries(:one)
  end

  test "visiting the index" do
    visit log_entries_url
    assert_selector "h1", text: "Log Entries"
  end

  test "creating a Log entry" do
    visit log_entries_url
    click_on "New Log Entry"

    fill_in "Details", with: @log_entry.details
    check "Failing" if @log_entry.failing
    fill_in "Message", with: @log_entry.message_id
    click_on "Create Log entry"

    assert_text "Log entry was successfully created"
    click_on "Back"
  end

  test "updating a Log entry" do
    visit log_entries_url
    click_on "Edit", match: :first

    fill_in "Details", with: @log_entry.details
    check "Failing" if @log_entry.failing
    fill_in "Message", with: @log_entry.message_id
    click_on "Update Log entry"

    assert_text "Log entry was successfully updated"
    click_on "Back"
  end

  test "destroying a Log entry" do
    visit log_entries_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Log entry was successfully destroyed"
  end
end
