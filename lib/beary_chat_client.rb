require 'httparty'

class BearyChatClient
  BASE_URL = "https://api.bearychat.com/v1"
  attr_accessor :token, :id, :base_url

  def initialize(token, opts = {})
    @token     = token
    @id        = opts[:id]
    @base_url  = opts[:base_url] || BASE_URL
  end

  def id
    @id ||= user_me["id"]
  end

  def create_message(body)
    post("message.create", body)
  end

  def create_message_for_user(uid, body)
    user_vchannel       = p2p(uid)["vchannel_id"]
    body["vchannel_id"] = user_vchannel

    create_message(body)
  end

  def list_p2p
    @list_p2p ||= get("p2p.list")
  end

  def p2p(user_id)
    list_p2p.find do |p2p|
      p2p["member_uids"].include?(id) && p2p["member_uids"].include?(user_id)
    end
  end

  def user_me
    @user_me ||= get("user.me")
  end

  protected
  def get(path, query = {})
    url           = "#{base_url}/#{path}"
    query[:token] = token

    HTTParty.get url, query: query
  end

  def post(path, body = {})
    url          = "#{base_url}/#{path}"
    body[:token] = token

    HTTParty.post url, body: body
  end
end
