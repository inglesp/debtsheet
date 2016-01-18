class Transfer < ActiveRecord::Base
  belongs_to :account, :required => true
  belongs_to :event, :required => true
end
