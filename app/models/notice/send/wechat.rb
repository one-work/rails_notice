module Notice
  module Send::Wechat
    extend ActiveSupport::Concern

    included do
      belongs_to :template_config, class_name: 'Wechat::TemplateConfig', foreign_key: [:notifiable_type, :code], primary_key: [:notifiable_type, :code], optional: true
    end

    def send_out
      super if defined? super
      return unless template_config

      wechat_users.includes(:app).map do |wechat_user|
        template = template_config.templates.find_by(appid: wechat_user.appid)
        next if template.nil?

        if ['Wechat::PublicApp', 'Wechat::PublicAgency'].include? wechat_user.app.type
          wechat_notice = Wechat::PublicNotice.new open_id: wechat_user.uid, appid: wechat_user.appid
        else
          wechat_notice = Wechat::ProgramNotice.new open_id: wechat_user.uid, appid: wechat_user.appid
        end

        wechat_notice.template = template
        wechat_notice.msg_request = template.msg_requests.where(open_id: wechat_user.uid).first
        wechat_notice.notification = self
        wechat_notice.save
        wechat_notice
      end
    end

  end
end
