require 'test_helper'

class SiteLayoutTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end

  def setup
    @user = users(:michael)
  end

  test "layout links" do
    get root_path
    assert_template 'static_pages/home'
    assert_select "a[href=?]", root_path, count: 2
    assert_select "a[href=?]", help_path
    assert_select "a[href=?]", about_path
    assert_select "a[href=?]", contact_path
    assert_select "a[href=?]", 'http://rubyonrails.org/', count: 1

    get contact_path
    assert_select "title", full_title("Contact")

    get signup_path
    assert_select "title", full_title("Sign up")

  end

  test "layout links with logged in user" do
    get root_path
    log_in_as(@user)
    get edit_user_path(@user)
    assert_select "a[href=?]", users_path
  end

  test "layout links with not logged in user" do
    get root_path
    assert_select "a[href=?]", users_path, false
  end
end
