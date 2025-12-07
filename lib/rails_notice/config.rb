module RailsNotice
  mattr_accessor :config, default: ActiveSupport::OrderedOptions.new

  config.link_host = ''
end
