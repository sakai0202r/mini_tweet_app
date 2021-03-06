require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(name: "Example User", email: "user@example.com",
                     password: "testpass",
                     password_confirmation: "testpass")
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "name should be present" do
    @user.name = "     "
    assert_not @user.valid?
  end

  test "email should be present" do
    @user.email = "     "
    assert_not @user.valid?
  end

  test "name should not be too long" do
    @user.name = "a" * 51
    assert_not @user.valid?
  end

  test "email should not be too long" do
    @user.email = "a" * 244 + "@example.com"
    assert_not @user.valid?
  end

  # メールアドレスは有効か
  test "email validation should accept valid addresses" do
    valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
                         first.last@foo.jp alice+bob@baz.cn]
    valid_addresses.each do |valid_address|
      @user.email = valid_address
      assert @user.valid?, "#{valid_address.inspect} should be valid"
    end
  end

  # メールアドレスのフォーマットを検証
  test "email validation should reject invalid addresses" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
                           foo@bar_baz.com foo@bar+baz.com]
    invalid_addresses.each do |invalid_address|
      @user.email = invalid_address
      assert_not @user.valid?, "#{invalid_address.inspect} should be invalid"
    end
  end

  test "email addresses should be unique" do
    duplicate_user = @user.dup
    # (dupは、同じ属性を持つデータを複製するためのメソッド)
    duplicate_user.email = @user.email.upcase
    @user.save
    assert_not duplicate_user.valid?
  end

  # メールアドレスは小文字であるか
  test "email addresses should be saved as lower-case" do
    mixed_case_email = "Foo@ExAMPle.CoM"
    @user.email = mixed_case_email
    @user.save
    assert_equal mixed_case_email.downcase, @user.reload.email
  end

  test "password should be present (nonblank)" do
   @user.password = @user.password_confirmation = " " * 6
   assert_not @user.valid?
 end

 test "password should have a minimum length" do
   @user.password = @user.password_confirmation = "a" * 5
   assert_not @user.valid?
 end

 test "associated posts should be destroyed" do
    @user.save
    @user.posts.create!(content: "Lorem ipsum")
    assert_difference 'Post.count', -1 do
      @user.destroy
    end
  end

  test "should follow and unfollow a user" do
    test = users(:test)
    test2  = users(:test2)
    assert_not test.following?(test2)
    test.follow(test2)
    assert test.following?(test2)
    assert test2.followers.include?(test)
    test.unfollow(test2)
    assert_not test.following?(test2)
  end

  test "feed should have the right posts" do
    test = users(:test)
    test2  = users(:test2)
    test3    = users(:test3)
    # フォローしているユーザーの投稿を確認
    test3.posts.each do |post_following|
      assert test.feed.include?(post_following)
    end
    # 自分自身の投稿を確認
    test.posts.each do |post_self|
      assert test.feed.include?(post_self)
    end
    # フォローしていないユーザーの投稿を確認
    test2.posts.each do |post_unfollowed|
      assert_not test.feed.include?(post_unfollowed)
    end
  end
end
