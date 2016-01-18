class Account < ActiveRecord::Base
  has_many :transfers
end
