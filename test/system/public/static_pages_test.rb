require "application_system_test_case"

class Public::StaticPagesTest < ApplicationSystemTestCase
  setup do
    @public_static_page = public_static_pages(:one)
  end

  test "visiting the index" do
    visit public_static_pages_url
    assert_selector "h1", text: "Static pages"
  end

  test "should create static page" do
    visit public_static_pages_url
    click_on "New static page"

    fill_in "Index", with: @public_static_page.index
    fill_in "Login", with: @public_static_page.login
    click_on "Create Static page"

    assert_text "Static page was successfully created"
    click_on "Back"
  end

  test "should update Static page" do
    visit public_static_page_url(@public_static_page)
    click_on "Edit this static page", match: :first

    fill_in "Index", with: @public_static_page.index
    fill_in "Login", with: @public_static_page.login
    click_on "Update Static page"

    assert_text "Static page was successfully updated"
    click_on "Back"
  end

  test "should destroy Static page" do
    visit public_static_page_url(@public_static_page)
    click_on "Destroy this static page", match: :first

    assert_text "Static page was successfully destroyed"
  end
end
