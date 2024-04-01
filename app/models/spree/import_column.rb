module Spree
    class ImportColumn < Spree::Base
  
      validates :import_id, presence: true
      belongs_to :import

    end
end