# coding: utf-8
require "timers"

class Pomodoro < ActiveRecord::Base
  POMODORO_INTERVAL_SECONDS = 5 * 60
  POMODORO_SECONDS = 25 * 60

  belongs_to :app, polymorphic: true

  belongs_to :pomodoro_app, foreign_key: :app_id

  scope :today, -> { where("created_at >= ? AND created_at < ?", Date.today, Date.tomorrow) }

  enum state: [:started, :droped, :ended]

  class << self
    def timer
      @timer ||= Timer.new
    end
  end

  # TODO: should not be able ended a droped pomodoro
  def state=(val)
    ended! if val == "ended"
  end

  def ended!
    update state: :ended, ended_at: Time.now
    start_pomodoro_notify
  end

  def start_pomodoro_notify
    Concurrent::ScheduledTask.new(POMODORO_INTERVAL_SECONDS) {
      text = "已经休息了 #{(POMODORO_INTERVAL_SECONDS/60).to_i} 分钟，请开始一个新的番茄吧！"

      pomodoro_app.create_message(vchannel_id, text)
    }.execute
  end

  def finish_pomodoro_notify
    Concurrent::ScheduledTask.new(POMODORO_SECONDS) {
      pomodoro_app.create_message(vchannel_id, "gify 休息一下吧")

      text = "已经工作了 #{(POMODORO_SECONDS/60).to_i} 分钟，如果番茄已完成，请发送 finish"

      pomodoro_app.create_message(vchannel_id, text)
    }.execute
  end

  class Timer
    def after(seconds, &block)
      Concurrent::ScheduledTask.new(2, &block).execute
    end
  end
end
