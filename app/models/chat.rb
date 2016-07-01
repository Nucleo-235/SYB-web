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
  
  has_many :chat_messages, -> { order('created_at DESC') }, dependent: :destroy

  def self.active_by_user(user1, user2)
    chat = Chat.find_by(user_1: user1, user_2: user2, closed: [nil, false])
    chat = Chat.find_by(user_1: user2, user_2: user1, closed: [nil, false]) unless chat
    chat
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

  def get_last_messages(previous_read_at)
    messages = self.chat_messages
    messages = messages.where('created_at > ?', previous_read_at) if previous_read_at
    messages = messages.limit(20) if !previous_read_at
    messages
  end

  def previous_messages(previous_message_id)
    self.chat_messages.where('id < ?', previous_message_id)
  end


  def self.find_or_create_chat(user1, user2)
    chat = Chat.active_by_user(user1, user2)
    if !chat
      chat = Chat.create(user_1: user1, user_2: user2, user_1_accepted: false, user_2_accepted: false)
    end
    chat
  end
end