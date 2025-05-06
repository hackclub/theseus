require "application_system_test_case"

class Letter::QueuesTest < ApplicationSystemTestCase
  setup do
    @letter_queue = letter_queues(:one)
  end

  test "visiting the index" do
    visit letter_queues_url
    assert_selector "h1", text: "Queues"
  end

  test "should create queue" do
    visit letter_queues_url
    click_on "New queue"

    fill_in "Name", with: @letter_queue.name
    fill_in "Slug", with: @letter_queue.slug
    fill_in "User", with: @letter_queue.user_id
    click_on "Create Queue"

    assert_text "Queue was successfully created"
    click_on "Back"
  end

  test "should update Queue" do
    visit letter_queue_url(@letter_queue)
    click_on "Edit this queue", match: :first

    fill_in "Name", with: @letter_queue.name
    fill_in "Slug", with: @letter_queue.slug
    fill_in "User", with: @letter_queue.user_id
    click_on "Update Queue"

    assert_text "Queue was successfully updated"
    click_on "Back"
  end

  test "should destroy Queue" do
    visit letter_queue_url(@letter_queue)
    click_on "Destroy this queue", match: :first

    assert_text "Queue was successfully destroyed"
  end
end
