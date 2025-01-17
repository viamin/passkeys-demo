class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new challenge create verify ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    if params[:password].present?
      if user = User.authenticate_by(params.permit(:email_address, :password))
        start_new_session_for user
        redirect_to after_authentication_url
      else
        redirect_to new_session_path, alert: "Try another email address or password."
      end
    else
      @user = User.find_by(email_address: params[:email_address])
      if @user&.passkeys&.any?
        @passkey_login = true
        render :new
      else
        @password_login = true
        render :new
      end
    end
  end

  def challenge
    @user = User.find_by(email_address: params[:email_address])

    if @user
      # prepare WebAuthn options
      get_options = WebAuthn::Credential.options_for_get(
        allow: @user.passkeys.pluck(:external_id),
        user_verification: "preferred"
      )

      # prepare session for passwordless
      session[:passkey_authentication] ||= {}
      unless session.dig(:passkey_authentication, :user_id)
        session[:passkey_authentication][:user_id] = @user.id
      end

      # save the challenge
      session[:passkey_authentication][:challenge] = get_options.challenge

      respond_to do |format|
        format.json { render json: get_options }
      end
    else
      respond_to do |format|
        format.json { render json: { message: "Authentication failed" }, status: :unprocessable_entity }
      end
    end
  end

  def verify
    credential = WebAuthn::Credential.from_get(params)
    @user = User.find(session.dig("passkey_authentication", "user_id"))
    passkey = @user.passkeys.find_by(external_id: credential.id)

    begin
      credential.verify(
        session.dig("passkey_authentication", "challenge"),
        public_key: passkey.public_key,
        sign_count: passkey.sign_count
      )
      passkey.update!(sign_count: credential.sign_count)
      start_new_session_for @user
      redirect_to after_authentication_url
    rescue WebAuthn::Error
      redirect_to new_session_path, alert: "Authentication failed"
    ensure
      session.delete(:passkey_authentication)
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  private

  def session_params
    params.permit(:username)
  end
end
