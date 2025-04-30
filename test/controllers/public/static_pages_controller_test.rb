require "test_helper"

class Public::StaticPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @public_static_page = public_static_pages(:one)
  end

  test "should get index" do
    get public_static_pages_url
    assert_response :success
  end

  test "should get new" do
    get new_public_static_page_url
    assert_response :success
  end

  test "should create public_static_page" do
    assert_difference("Public::StaticPage.count") do
      post public_static_pages_url, params: { public_static_page: { index: @public_static_page.index, login: @public_static_page.login } }
    end

    assert_redirected_to public_static_page_url(Public::StaticPage.last)
  end

  test "should show public_static_page" do
    get public_static_page_url(@public_static_page)
    assert_response :success
  end

  test "should get edit" do
    get edit_public_static_page_url(@public_static_page)
    assert_response :success
  end

  test "should update public_static_page" do
    patch public_static_page_url(@public_static_page), params: { public_static_page: { index: @public_static_page.index, login: @public_static_page.login } }
    assert_redirected_to public_static_page_url(@public_static_page)
  end

  test "should destroy public_static_page" do
    assert_difference("Public::StaticPage.count", -1) do
      delete public_static_page_url(@public_static_page)
    end

    assert_redirected_to public_static_pages_url
  end
end
