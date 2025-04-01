require "application_system_test_case"

class LettersTest < ApplicationSystemTestCase
  setup do
    @letter = letters(:one)
  end

  test "visiting the index" do
    visit letters_url
    assert_selector "h1", text: "Letters"
  end

  test "should create letter" do
    visit letters_url
    click_on "New letter"

    click_on "Create Letter"

    assert_text "Letter was successfully created"
    click_on "Back"
  end

  test "should update Letter" do
    visit letter_url(@letter)
    click_on "Edit this letter", match: :first

    click_on "Update Letter"

    assert_text "Letter was successfully updated"
    click_on "Back"
  end

  test "should destroy Letter" do
    visit letter_url(@letter)
    click_on "Destroy this letter", match: :first

    assert_text "Letter was successfully destroyed"
  end
end
