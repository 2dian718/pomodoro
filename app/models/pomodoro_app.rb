# coding: utf-8
require "beary_chat_client"

class PomodoroApp < ApplicationRecord
  has_many :pomodoros, as: :app, dependent: :destroy

  def receive(message)
    text = (message[:text] || "").split.first

    case text
    when "start"
      start(message)
    when "stop"
      stop(message)
    when "finish"
      finish(message)
    when "summary"
      summary(message)
    else
      # TODO: give help or ls
      nil
    end
  end

  def start(message)
    pomodoro = pomodoros.create(vchannel_id: message["vchannel"],
                                sender: message[:sender])

    pomodoro.finish_pomodoro_notify

    create_message(message["vchannel"], "gify clock")

    text     = "开始计时！"
    create_message(message["vchannel"], text)
  end

  def stop(message)
    pomodoro = Pomodoro.started.find_by_sender message[:sender]

    text = if pomodoro
             # TODO: add time consuming
             pomodoro.droped!

             "已丢弃一个番茄。"
           else
             "没有进行中的番茄，使用 start 开始一个番茄吧！"
           end

    create_message(message["vchannel"], text)
  end

  def finish(message)
    pomodoro = Pomodoro.started.find_by_sender message[:sender]

    if pomodoro
      pomodoro.ended!
      create_message(message["vchannel"], "gify cheer")

      create_message(message["vchannel"], "恭喜你，完成一个番茄！")
    else
      create_message(message["vchannel"], "没有进行中的番茄，使用 start 开始一个番茄吧！")
    end
  end

  def summary(message)
    pomodoros       = Pomodoro.where(sender: message[:sender]).today
    pomodoros_count = pomodoros.count

    create_message(message["vchannel"], "今天已经完成了 #{pomodoros_count} 个番茄")
    create_message(message["vchannel"], "gify awesome")
  end

  def create_message(vchannel_id, text)
    body = {
      text: text,
      vchannel_id: vchannel_id,
      attachments: []
    }

    client.create_message(body)
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
  def client
    @client ||= BearyChatClient.new(token, base_url: "https://api.bearychat.com/v1")
  end
end
