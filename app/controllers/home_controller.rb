class HomeController < ApplicationController
  def show
  end

  def redirect
    client = Signet::OAuth2::Client.new({
      client_id: Rails.application.secrets.client_id,
      client_secret: Rails.application.secrets.client_secret,
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      scope: Google::Apis::GmailV1::AUTH_GMAIL_READONLY,
      redirect_uri: url_for(:action => :callback)
    })

    redirect_to client.authorization_uri.to_s
  end

  def callback
    client = Signet::OAuth2::Client.new({
      client_id: Rails.application.secrets.client_id,
      client_secret: Rails.application.secrets.client_secret,
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      redirect_uri: url_for(:action => :callback),
      code: params[:code]
    })
    response = client.fetch_access_token!
    session[:access_token] = response['access_token']

    redirect_to url_for(:action => :mail_parse)
  end

  def mail_parse
    client = Signet::OAuth2::Client.new(access_token: session[:access_token])
    client.expires_in = Time.now + 1_000_000

    service = Google::Apis::GmailV1::GmailService.new

    service.authorization = client

    @emails = service.list_user_messages('me', max_results: 10, q: "from:amazon label:updates confirm")
    @email_array = []
    if set = @emails.messages
      set.each do |i|
        email = service.get_user_message('me', i.id)
        my_email = {
         date: email.payload.headers.find {|h| h.name == "Date" }.value,
         body: email.payload.parts.first.body.data
        }
        @email_array.push(my_email)
      end
    end
    MailParser.new(@email_array)
  end

end
