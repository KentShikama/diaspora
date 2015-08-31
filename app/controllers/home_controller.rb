#   Copyright (c) 2010-2012, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class HomeController < Devise::SessionsController
  after_filter :reset_authentication_token, only: [:create]
  before_filter :reset_authentication_token, only: [:destroy]

  layout proc { "application" }

  def reset_authentication_token
    current_user.reset_authentication_token!
  end

  def new
    super
  end

  def toggle_mobile
    session[:mobile_view] = session[:mobile_view].nil? ? true : !session[:mobile_view]
    redirect_to :back
  end

  def force_mobile
    session[:mobile_view] = true

    redirect_to stream_path
  end
end
