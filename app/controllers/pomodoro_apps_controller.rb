class PomodoroAppsController < ApplicationController
  def message
    app     = PomodoroApp.find_or_create_by token: params[:token]
    message = params.slice(:subdomain, :vchannel, :sender,
                           :username, :text, :key)

    app.receive(message)

    render json: "Success"
  end
end
