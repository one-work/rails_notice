module Notice
  class Announcement < ApplicationRecord
    include Model::Announcement
    include Ext::Notifiable
    include Ext::MemberNotifiable
  end
end
