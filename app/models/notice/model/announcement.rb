module Notice
  module Model::Announcement
    extend ActiveSupport::Concern

    included do
      attribute :type, :string
      attribute :title, :string
      attribute :body, :string
      attribute :link, :string
      attribute :notifications_count, :integer, default: 0
      attribute :readed_count, :integer, default: 0

      belongs_to :organ, class_name: 'Org::Organ', optional: true
      belongs_to :publisher, polymorphic: true, optional: true
      has_many :notifications, as: :notifiable

      validates :body, presence: true

      has_one_attached :cover
    end

    def cover_url
      cover.url if cover.present?
    end

    def reset_counter
      self.notifications_count = self.notifications.count
      self.readed_count = self.notifications.readed.count
      self.save
    end

  end
end
