module Notice
  class Admin::MembersController < Admin::BaseController
    before_action :set_member, only: [:show, :edit, :update]

    def index
      q_params = {}
      q_params.merge! default_params
      q_params.merge! params.permit(:id)

      @members = Org::Member.default_where(q_params).order(id: :asc).page(params[:page])
    end

    private
    def set_member
      @member = Org::Member.find(params[:id])
    end

    def member_params
      params.fetch(:member, {}).permit(
        :showtime,
        :accept_email,
        notifiable_types: []
      )
    end

  end
end
