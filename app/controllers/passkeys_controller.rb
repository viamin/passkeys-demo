# frozen_string_literal: true

class PasskeysController < ApplicationController
  def challenge
    # Generate WebAuthn ID if the user does not have any yet
    current_user.update(passkey_id: WebAuthn.generate_user_id) unless current_user.passkey_id

    # Prepare the data needed for a challenge
    create_options = WebAuthn::Credential.options_for_create(
      user: {
        id: current_user.passkey_id,
        name: current_user.email_address # or username, etc.
      },
      exclude: current_user.passkeys.pluck(:external_id)
    )

    # Generate the challenge and save it into the session
    session[:passkey_register_challenge] = create_options.challenge

    respond_to do |format|
      format.json { render json: create_options }
    end
  end

  def create
    # Create WebAuthn Credentials from the request params
    passkey_credential = WebAuthn::Credential.from_create(passkey_params)

    # Verify the challenge
    passkey_credential.verify(session[:passkey_register_challenge])

    # The validation would raise WebAuthn::Error so if we are here, the credentials are valid, and we can save it
    passkey = current_user.passkeys.new(
      external_id: passkey_credential.id,
      public_key: passkey_credential.public_key,
      nickname: passkey_params[:nickname],
      sign_count: passkey_credential.sign_count
    )

    if passkey.save
      redirect_to users_settings_path, notice: "Passkey added"
    else
      render turbo_stream: turbo_stream.update("passkey_error", "<p class=\"text-red-500\">Couldn't add your Security Key</p>")
    end
  rescue WebAuthn::Error => e
    render turbo_stream: turbo_stream.update("passkey_error", "<p class=\"text-red-500\">Verification failed: #{e.message}</p>")
  ensure
    session.delete(:passkey_register_challenge)
  end

  def destroy
    passkey = current_user.passkeys.find(params[:id])
    passkey.destroy

    render turbo_stream: turbo_stream.remove(passkey)
  end

  private

  def passkey_params
    params.permit(:type, :id, :rawId, :clientExtensionResults, :authenticatorAttachment, :nickname,
      response: [ :attestationObject, :clientDataJSON, { transports: [] } ])
  end
end
