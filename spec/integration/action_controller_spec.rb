require 'spec_helper'

  describe "Pages" do
    before :each do
      @user = User.create!(name: "Jane Smith")
    end
    
    it "may reward users with points for visiting" do
      visit posts_path # Should now get the extra 6 points
      visit user_path(@user)
      page.should have_content("Points: 11")
      # visit posts_path # Should now get the extra 6 points
      # visit user_path(@user)
      # page.should have_content("Points: 17")
      # visit posts_path # Should now get the extra 6 points
      # visit user_path(@user)
      # page.should have_content("Points: 23")
    end
  end