# coding: utf-8
require "timers"

class Pomodoro < ActiveRecord::Base
  POMODORO_INTERVAL_SECONDS = 5 * 60

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
    start_a_pomodoro_notify
  end

  def start_a_pomodoro_notify
    self.class.timer.after(POMODORO_INTERVAL_SECONDS) do
      text = "已经休息了 #{POMODORO_INTERVAL_SECONDS/60} 分钟，请开始一个新的番茄吧！"

      pomodoro_app.create_message(vchannel_id, text)
    end
  end

  class Timer
    def after(seconds, &block)
      start

      @timers.after(seconds, &block)
    end

    def start
      @timers ||= Timers::Group.new

      Thread.new { run }
    end

    def run
      loop do
        @timers.wait
      end
    end
  end
end
