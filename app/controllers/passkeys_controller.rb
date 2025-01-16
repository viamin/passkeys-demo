class PasskeysController < ApplicationController
  def create
    create_options = WebAuthn::Credential.options_for_create(
      user: {
        id: current_user.passkey_id,
        name: current_user.email_address
      },
      exclude: current_user.passkeys.pluck(:external_id),
      authenticator_selection: { user_verification: "required" }
    )

    session[:current_registration] = { challenge: create_options.challenge }

    respond_to do |format|
      format.js { render json: create_options }
    end
  end

  def callback
    webauthn_credential = WebAuthn::Credential.from_create(params)

    begin
      webauthn_credential.verify(session[:current_registration]["challenge"], user_verification: true)

      passkey = current_user.passkeys.find_or_initialize_by(
        external_id: Base64.strict_encode64(webauthn_credential.raw_id)
      )

      if passkey.update(
        nickname: params[:credential_nickname],
        public_key: webauthn_credential.public_key,
        sign_count: webauthn_credential.sign_count
        )
        render json: { status: "ok" }, status: :ok
      else
        render json: "Couldn't add your Passkey", status: :unprocessable_entity
      end
    rescue WebAuthn::Error => e
      render json: "Verification failed: #{e.message}", status: :unprocessable_entity
    ensure
      session.delete(:current_registration)
    end
  end

  def destroy
    if current_user&.can_delete_credentials?
      current_user.passkeys.destroy(params[:id])
    end

    redirect_to users_settings_path
  end
end
