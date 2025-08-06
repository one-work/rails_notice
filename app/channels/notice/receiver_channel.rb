module Notice
  class ReceiverChannel < ApplicationCable::Channel

    def subscribed
      if verified_receiver.is_a?(Auth::Session)
        stream_from "notice:receiver:#{verified_receiver.identity}"
      else
        stream_from "notice:receiver:#{verified_receiver}"
      end
    end

    def unsubscribed
    end

  end
end
