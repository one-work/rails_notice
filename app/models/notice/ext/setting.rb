module Notice
  module Ext::Setting
    extend ActiveSupport::Concern

    included do
      attribute :notifiable_types, :json, default: []
      attribute :counters, :json, default: {}
      attribute :showtime, :integer, default: 0
      attribute :accept_email, :boolean, default: true

      normalizes :notifiable_types, with: -> (params) { params.compact_blank }
    end

    def unread_count
      r = counters&.fetch('total', 0)
      r.to_i
    end

    def reset_unread_count
      update counters: compute_unread_count
    end

    class_methods do

      def increment_unread_counter(col, num = 1)
        s = "jsonb_set(counters, '{#{col}}', (COALESCE(counters->>'#{col}', '0')::int + #{num})::text::jsonb)"

        sql = "counters = #{s}"
        update_all sql
      end

      def decrement_unread_counter(col, num = 1)
        s = "jsonb_set(counters, '{#{col}}', (COALESCE(counters->>'#{col}', '0')::int - #{num})::text::jsonb)"

        sql = "counters = #{s}"
        update_all sql
      end

      def reset_notice_counters
        self.find_each do |ns|
          ns.reset_unread_count
        end
      end

    end

  end
end
