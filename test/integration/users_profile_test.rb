require 'test_helper'

class UsersProfileTest < ActionDispatch::IntegrationTest
  include ApplicationHelper

  def setup
    @user = users(:michael)
  end

  test "profile display" do
    get user_path(@user)
    assert_template 'users/show'
    assert_select 'title', full_title(@user.name)
    assert_select 'h1', text: @user.name
    assert_select 'h1>img.gravatar'
    assert_match @user.microposts.count.to_s, response.body
    assert_select 'div.pagination', count: 1
    @user.microposts.paginate(page: 1).each do |micropost|
      assert_match micropost.content, response.body
    end
  end

  test "home page stats test" do
    log_in_as(@user)
    archer = users(:archer)
    lana = users(:lana)
    # # follow some user
    # @user.follow(archer)
    # @user.follow(lana)
    # # followed by some user
    # archer.follow(@user)
    # lana.follow(@user)
    get root_path
    assert_template 'static_pages/home'
    assert_template 'static_pages/_loggedin'
    assert_select 'a[href=?]', "/users/#{@user.id}/following"
    assert_select '#following', text: "#{@user.following.count}"
    assert_select 'a[href=?]', "/users/#{@user.id}/followers"
    assert_select '#followers', text: "#{@user.followers.count}"
  end
end
