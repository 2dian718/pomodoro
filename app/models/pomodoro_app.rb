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
    when "help"
      help(message)
    else
      help(message)
    end
  end

  def help(message)
    text = "番茄工作法是简单易行的时间管理方法，是由弗朗西斯科•西里洛于1992年创立的一种相对于GTD更微观的时间管理方法。使用番茄工作法，选择一个待完成的任务，将番茄时间设为25分钟，专注工作，中途不允许做任何与该任务无关的事，直到番茄时钟响起，然后在纸上画一个X短暂休息一下（5分钟就行）。\n如果需要开始一个番茄，请输入 start。\n如果完成了一个番茄，请输入 finish。\n如果终止一个番茄，请输入 stop。\n如果想知道今天完成了多少番茄，请输入 summary。\n"

    create_message(message["vchannel"], text)
  end

  def start(message)
    pomodoro = pomodoros.create(vchannel_id: message["vchannel"],
                                sender: message[:sender])

    pomodoro.finish_pomodoro_notify

    text     = "开始计时！"
    create_message_with_image(message["vchannel"], text, Giphy.random("clock").image_url)
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

      create_message_with_image(message["vchannel"], "恭喜你，完成一个番茄！", Giphy.random("cheer").image_url)
    else
      create_message(message["vchannel"], "没有进行中的番茄，使用 start 开始一个番茄吧！")
    end
  end

  def summary(message)
    pomodoros       = Pomodoro.where(sender: message[:sender]).today
    pomodoros_count = pomodoros.count

    create_message_with_image(message["vchannel"], "今天已经完成了 #{pomodoros_count} 个番茄", Giphy.random("awesome").image_url)
  end

  def create_message(vchannel_id, text)
    body = {
      text: text,
      vchannel_id: vchannel_id,
      attachments: []
    }

    client.create_message(body)
  end

  def create_message_with_image(vchannel_id, text, image)
    body = {
      text: text,
      vchannel_id: vchannel_id,
      attachments: [
        {
          images: [
            { url: image }
          ]
        }]}

    client.create_message(body)
  end

  private
  def client
    @client ||= BearyChatClient.new(token, base_url: "https://api.bearychat.com/v1")
  end
end
