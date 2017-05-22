# == Schema Information
#
# Table name: chats
#
#  id                  :integer          not null, primary key
#  user_1_id           :integer          not null
#  user_2_id           :integer          not null
#  user_1_accepted     :boolean
#  user_2_accepted     :boolean
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  closed              :boolean
#  closed_at           :datetime
#  user_1_last_read_at :datetime
#  user_2_last_read_at :datetime
#

class Chat < ActiveRecord::Base
  belongs_to :user_1, :class_name => "User"
  belongs_to :user_2, :class_name => "User"

  validates_presence_of :user_1, :user_2
  validates_uniqueness_of :user_1, :scope => :user_2
  validate :check_blocked_users
  
  has_many :chat_messages, -> { order('created_at DESC') }, dependent: :destroy
  has_many :chat_apparels, dependent: :destroy
  has_many :apparels, through: :chat_apparels
  
  after_create :send_push

  def self.active_by_user(user1, user2)
    chat = Chat.find_by(user_1: user1, user_2: user2, closed: [nil, false])
    chat = Chat.find_by(user_1: user2, user_2: user1, closed: [nil, false]) unless chat
    chat
  end

  def user_apparels(user)
    apparels.where(user: user)
  end

  def mark_as_read(user)
    self.user_1_last_read_at = Time.now if user.id == user_1_id
    self.user_2_last_read_at = Time.now if user.id == user_2_id
    self.save
  end

  def last_read_date(user)
    if user.id == user_1_id && user_1_last_read_at
      user_1_last_read_at
    elsif user.id == user_2_id && user_2_last_read_at
      user_2_last_read_at
    else
      nil
    end
  end

  def is_owner(user)
    user.id == user_1_id || user.id == user_2_id
  end

  def get_last_messages(previous_read_at, user = nil)
    messages = self.chat_messages
    messages = messages.where('created_at > ?', previous_read_at) if previous_read_at
    messages = messages.where.not(user: user) if user
    messages = messages.limit(20) if !previous_read_at
    messages
  end

  def previous_messages(previous_message_id)
    self.chat_messages.where('id < ?', previous_message_id)
  end

  def create_chat_apparels
    ApparelRating.where(user: user_1, liked: true, apparel: user_2.apparels).each do |rating|
      self.chat_apparels.find_or_create_by(chat: self, apparel: rating.apparel)
    end
    ApparelRating.where(user: user_2, liked: true, apparel: user_1.apparels).each do |rating|
      self.chat_apparels.find_or_create_by(chat: self, apparel: rating.apparel)
    end
  end

  def other_recipients(user)
    recipients = []
    if user
      recipients.push(user_1) if user_1_id != user.id
      recipients.push(user_2) if user_2_id != user.id
    end
    recipients
  end

  def other_non_blocked_recipients(user)
    recipients = self.other_recipients(user)
    recipients = recipients.select do |other_user|
      blocked_user_ids = other_user.blocked_users.select(:blocked_user_id)
      result = blocked_user_ids.include? user.id
      result
    end
    recipients
  end

  def self.find_or_create_chat(user1, user2)
    chat = Chat.active_by_user(user1, user2)
    if !chat
      chat = Chat.create(user_1: user1, user_2: user2, user_1_accepted: false, user_2_accepted: false)
    end
    chat.create_chat_apparels
    chat
  end

  def send_push
    if user_1 && user_2
      do_send_push(user_1, 'Combinou!', self.user_2.public_name + ' também gostou das suas peças ...', nil, 'shareyourbber_new_match', { chat_id: self.id, type: 'match' })
      do_send_push(user_2, 'Combinou!', self.user_1.public_name + ' também gostou das suas peças ...', nil, 'shareyourbber_new_match', { chat_id: self.id, type: 'match' })
    end
  end

  protected
    def check_blocked_users
      if user_1 && user_2
        result = true
        blocked_user_1_ids = user_1.blocked_users.select(:blocked_user_id)
        if blocked_user_1_ids.include? user_2.id
          errors.add(:user_2, :blocked)
          result = false
        end

        blocked_user_2_ids = user_2.blocked_users.select(:blocked_user_id)
        if blocked_user_2_ids.include? user_1.id
          errors.add(:user_1, :blocked)
          result = false
        end

        return false if !result
      end
    end

    def do_send_push(user, title, message, image, push_collapse_key, extraData)
      android_ids = Device.where(provider: 'android', user: user).map { |e| e.uid  }
      PushSender.instance.send_android_push(android_ids, title, message, image, push_collapse_key, extraData) if android_ids.length

      ios_ids = Device.where(provider: 'ios', user: user).map { |e| e.uid  }
      PushSender.instance.send_ios_push(ios_ids, title, message, image, push_collapse_key, extraData) if android_ids.length
    end
end
