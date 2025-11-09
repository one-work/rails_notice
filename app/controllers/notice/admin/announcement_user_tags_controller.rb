module Notice
  class Admin::AnnouncementUserTagsController < Admin::BaseController
    before_action :set_announcement
    before_action :set_new_announcement_organ, only: [:new, :create]

    def index
      @announcement_organs = @announcement.announcement_organs
    end

    private
    def set_announcement
      @announcement = Announcement.find params[:announcement_id]
    end

    def set_departments
      @departments = Org::Department.default_where(default_params)
    end

    def set_new_announcement_organ
      @announcement_organ = @announcement.announcement_organs.build(announcement_organ_params)
    end

    def announcement_organ_params
      _p = params.fetch(:announcement_organ, {}).permit(
        :organ_id
      )
      _p.with_defaults! default_form_params
    end

  end
end
