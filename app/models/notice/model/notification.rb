module Notice
  module Model::Notification
    extend ActiveSupport::Concern

    included do
      attribute :type, :string
      attribute :state, :string
      attribute :title, :string
      attribute :body, :string
      attribute :link, :string
      attribute :sending_at, :datetime
      attribute :read_at, :datetime, index: true
      attribute :code, :string, default: 'default'
      attribute :official, :boolean, default: false
      attribute :archived, :boolean, default: false
      attribute :verbose, :boolean, default: false
      attribute :created_at, :datetime, null: false, index: true
      attribute :receiver_id, :uuid, index: true

      belongs_to :organ, class_name: 'Org::Organ', optional: true

      belongs_to :sender, polymorphic: true, optional: true
      belongs_to :notifiable, polymorphic: true, optional: true
      belongs_to :linked, polymorphic: true, optional: true

      has_many :notification_sendings, dependent: :delete_all

      scope :unread, -> { where(read_at: nil, archived: false) }
      scope :readed, -> { where.not(read_at: nil, archived: false) }

      after_create :increment_unread, if: -> { read_at.blank? }
      after_destroy :decrement_unread, if: -> { read_at.blank? }
      after_create_commit :process_job
    end

    def store_other_params(other_params)
      if other_params[:sender]
        #return if other_params[:sender] == receiver  # do not send notification to himself
        self.sender_id = other_params[:sender].id
        self.sender_type = other_params[:sender].class
      end

      if other_params[:linked]
        self.linked_type = other_params[:linked].class.name
        self.linked_id = other_params[:linked].id
      end

      self.assign_attributes other_params.slice(
        :title, :body, :link, :organ_id,
        :verbose, :code,
        :cc_emails
      )
    end

    def process_job
      if sending_at
        NotificationJob.set(wait_until: sending_at).perform_later(self)
      else
        NotificationJob.perform_later(self)
      end
    end

    def send_out
    end

    def notifiable_detail
      r = {
        'title' => title,
        'body' => body
      }
      r.merge! self.notifiable.attributes.slice(*notify_setting[:only])
      Array(notify_setting[:methods]).each do |m|
        r.merge! m => notifiable.try(m)
      end
      r
    end

    def linked_detail
      r = self.linked.as_json(**linked_setting.slice(:only, :except, :include, :methods))
      Hash(r)
    end

    def linked_setting
      RailsNotice.notifiable_types.dig(linked_type, self.code.to_sym) || {}
    end

    def notifiable_attributes
      if verbose
        r = notifiable_detail
        r.transform_values! do |i|
          next i unless i.acts_like?(:time)
          if self.user.respond_to?(:timezone)
            time_zone = self.user.timezone
          else
            time_zone = Time.zone.name
          end
          i.in_time_zone(time_zone).strftime '%Y-%m-%d %H:%M:%S'
        end
        r
      else
        {}
      end
    end

    def notify_setting
      self.class.default_hash.dig(notifiable_type, self.code) || {}
    end

    def tr_key(column)
      return unless notifiable
      "#{self.class.i18n_scope}.notify.#{notifiable.class.base_class.model_name.i18n_key}.#{self.code}.#{column}"
    end

    def tr_value(column)
      keys = RailsNotice::I18nHelper.interpolate_key(I18n.t(tr_key(column)))
      notifiable_detail.with_indifferent_access.slice *keys
    end

    def title
      return super if super.present?

      if I18n.exists? tr_key(:title)
        tr_values = tr_value(:title)
        tr_values.merge! notify_setting.fetch(:tr_values, {})
        return I18n.t tr_key(:title), tr_values.symbolize_keys
      end

      if notifiable.respond_to?(:title)
        notifiable.title
      end
    end

    def body
      return super if super.present?

      if I18n.exists? tr_key(:body)
        tr_values = tr_value(:body)
        tr_values.merge! notify_setting.fetch(:tr_values, {})
        return I18n.t tr_key(:body), tr_values.symbolize_keys
      end

      if notifiable.respond_to?(:body)
        notifiable.body
      end
    end

    def make_as_read
      return unless self.read_at.blank?
      self.read_at = Time.current
      notifiable.readed_count += 1 if notifiable.class.attribute_method?(:readed_count)
      self.class.transaction do
        decrement_unread if just_readed?
        notifiable.save!
        save!
      end
    end

    def make_as_unread
      return if self.read_at.blank?
      self.read_at = nil
      self.class.transaction do
        increment_unread if read_at_changed?
        save!
      end
    end

    def link
      if super.present?
        super
      elsif linked_type && linked_id
        url = URI(RailsNotice.config.link_host)
        url.path = "/#{linked_type.underscore}/#{linked_id}"
        url.to_s
      else
        url = URI(RailsNotice.config.link_host)
        url.path = "/#{self.class.name.underscore}/#{self.id}"
        url.to_s
      end
    end

    def just_readed?
      read_at_changed? && read_at_change[0].nil? && read_at_change[1].acts_like?(:time)
    end

    def saved_readed?
      saved_change_to_read_at && saved_change_to_read_at[0].nil? && saved_change_to_read_at[1].acts_like?(:time)
    end

    def archive
      self.read_at ||= Time.current
      self.archived = true
      self.class.transaction do
        decrement_unread if just_readed?
        save!
      end
    end

    class_methods do
      def notifiable_types
        self.unscoped.select(:notifiable_type).distinct.pluck(:notifiable_type).compact.sort!
      end

      def default_hash
        if Rails.root.join('config/notice.yml').exist?
          init_hash = YAML.load_file(Rails.root.join('config/notice.yml'), aliases: true, fallback: {})
        else
          init_hash = {}
        end

        Rails::Engine.subclasses.each_with_object(init_hash) do |engine, ha|
          icon_path = engine.root.join('config/notice.yml')
          if icon_path.exist?
            YAML.safe_load_file(icon_path, aliases: true, fallback: {}).each do |k, v|
              ha[k] ||= {}
              ha[k].with_defaults! v
            end
          end
        end
      end
    end

  end
end
