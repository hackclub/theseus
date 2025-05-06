require "test_helper"

class Letter::QueuesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @letter_queue = letter_queues(:one)
  end

  test "should get index" do
    get letter_queues_url
    assert_response :success
  end

  test "should get new" do
    get new_letter_queue_url
    assert_response :success
  end

  test "should create letter_queue" do
    assert_difference("Letter::Queue.count") do
      post letter_queues_url, params: { letter_queue: { name: @letter_queue.name, slug: @letter_queue.slug, user_id: @letter_queue.user_id } }
    end

    assert_redirected_to letter_queue_url(Letter::Queue.last)
  end

  test "should show letter_queue" do
    get letter_queue_url(@letter_queue)
    assert_response :success
  end

  test "should get edit" do
    get edit_letter_queue_url(@letter_queue)
    assert_response :success
  end

  test "should update letter_queue" do
    patch letter_queue_url(@letter_queue), params: { letter_queue: { name: @letter_queue.name, slug: @letter_queue.slug, user_id: @letter_queue.user_id } }
    assert_redirected_to letter_queue_url(@letter_queue)
  end

  test "should destroy letter_queue" do
    assert_difference("Letter::Queue.count", -1) do
      delete letter_queue_url(@letter_queue)
    end

    assert_redirected_to letter_queues_url
  end
end
