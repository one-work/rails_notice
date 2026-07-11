module Notice
  module Send::Socket

    def send_out
      super if defined? super

      content = ApplicationController.render(formats: [:turbo_stream], partial: 'notice_push', locals: { model: self })
      #ReceiverChannel.broadcast_to(member.identity, content)
      self.notification_sendings.find_or_create_by(way: 'websocket', sent_to: receiver_id)
    end

    def sent_member_out
      ReceiverChannel.broadcast_to(user_id, {
        id: id,
        body: body,
        count: user.unread_count,
        link: link,
        showtime: user.showtime
      })
      self.notification_sendings.find_or_create_by(way: 'websocket', sent_to: receiver_id)
    end

  end
end
