module Notice
  module Model::Notification::UserNotification
    extend ActiveSupport::Concern

    included do
      belongs_to :user, class_name: 'Auth::User', foreign_key: :receiver_id
    end

    def wechat_users
      user.wechat_users.default_where(appid: organ.apps.where(type: ['Wechat::PublicApp', 'Wechat::PublicAgency']).pluck(:appid)).pluck(:uid)
    end

    def increment_unread
      counters = ['total', notifiable_type]
      counters << 'official' if self.official
      counters.each do |counter|
        user.counters[counter] = user.counters[counter].to_i + 1
      end
      user.save
    end

    def decrement_unread
      counters = ['total', notifiable_type]
      counters << 'official' if self.official
      counters.each do |counter|
        user.counters[counter] = user.counters[counter].to_i - 1
      end
      user.save
    end

    def reset_unread_count
      user.reset_unread_count
    end

  end
end
