require "beary_chat_client"

class PomodoroApp < ApplicationRecord
  has_many :pomodoros, as: :app, dependent: :destroy

  def reply(message)
    message_content = JSON.parse(message[:text])

    return nil if message_content["path"] != "pomodoros"

    case message_content["method"]
    when "POST"
      create_pomodoro(message)
    when "PATCH"
      update_pomodoro(message)
    when "GET"
      find_pomodoros(message)
    end
  end

  def create_pomodoro(message)
    pomodoro = pomodoros.create(vchannel_id: message["vchannel"])
    text     = present_pomodoro(pomodoro).to_json

    create_message(message["vchannel"], text)
  end

  def update_pomodoro(message)
    content  = JSON.parse(message[:text])
    pomodoro = Pomodoro.find content["data"]["id"]
    params   = content["data"].slice("name", "state")
    pomodoro.update(params)
    text     = present_pomodoro(pomodoro).to_json

    create_message(message["vchannel"], text)
  end

  def find_pomodoros(message)
    content     = JSON.parse(message[:text])
    vchannel_id = message["vchannel"]
    pomodoros   = Pomodoro.where(vchannel_id: vchannel_id)
    pomodoros   = pomodoros.today if content["data"]["today"]
    text        = pomodoros.map { |pomodoro| present_pomodoro(pomodoro) }.to_json

    create_message(message["vchannel"], text)
  end

  def create_message(vchannel_id, text)
    body = {
      text: text,
      vchannel_id: vchannel_id,
      attachments: []
    }

    client.create_message(body)
  end

  private
  def present_pomodoro(pomodoro)
    pomodoro.slice(:id, :name, :state, :created_at, :ended_at, :vchannel_id)
  end

  def client
    @client ||= BearyChatClient.new(token, id: meta[:id], base_url: "https://api.bearychat.com/v1")
  end
end
