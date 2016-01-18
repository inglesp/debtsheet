class Event < ActiveRecord::Base
  has_many :transfers

  class InvalidInput < StandardError; end
end
