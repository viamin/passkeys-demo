class UsersController < ApplicationController
  def settings
    @user = Current.session.user
  end
end
