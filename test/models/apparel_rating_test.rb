# == Schema Information
#
# Table name: apparel_ratings
#
#  id         :integer          not null, primary key
#  apparel_id :integer          not null
#  user_id    :integer          not null
#  liked      :boolean          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#

require 'test_helper'

class ApparelRatingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
