require 'ougai/formatters/bunyan'
require 'logger'

module Ougai
  class Logger < ::Logger
    attr_accessor :default_message, :exc_key

    def initialize(*args)
      super(*args)
      @default_message = 'No message'
      @exc_key = :err
      @formatter = create_formatter
    end

    def debug(message = nil, ex = nil, data = nil, &block)
      return true if level > DEBUG
      args = block ? yield : [message, ex, data]
      add(DEBUG, to_item(args))
    end

    def info(message = nil, ex = nil, data = nil, &block)
      return true if level > INFO
      args = block ? yield : [message, ex, data]
      add(INFO, to_item(args))
    end

    def warn(message = nil, ex = nil, data = nil, &block)
      return true if level > WARN
      args = block ? yield : [message, ex, data]
      add(WARN, to_item(args))
    end

    def error(message = nil, ex = nil, data = nil, &block)
      return true if level > ERROR
      args = block ? yield : [message, ex, data]
      add(ERROR, to_item(args))
    end

    def fatal(message = nil, ex = nil, data = nil, &block)
      return true if level > FATAL
      args = block ? yield : [message, ex, data]
      add(FATAL, to_item(args))
    end

    def unknown(message = nil, ex = nil, data = nil, &block)
      args = block ? yield : [message, ex, data]
      add(UNKNOWN, to_item(args))
    end

    def self.broadcast(logger)
      Module.new do |mdl|
        ::Logger::Severity.constants.each do |severity|
          method_name = severity.downcase.to_sym

          mdl.send(:define_method, method_name) do |*args|
            logger.send(method_name, *args)
            super(*args)
          end
        end
      end
    end

    protected

    def create_formatter
      Formatters::Bunyan.new
    end

    private

    def to_item(args)
      msg, ex, data = args

      item = {}
      if ex.nil?       # 1 arg
        if msg.is_a?(Exception)
          item[:msg] = msg.to_s
          set_exc(item, msg)
        elsif msg.is_a?(Hash)
          item[:msg] = @default_message unless msg.key?(:msg)
          item.merge!(msg)
        else
          item[:msg] = msg.to_s
        end
      elsif data.nil?  # 2 args
        if ex.is_a?(Exception)
          item[:msg] = msg.to_s
          set_exc(item, ex)
        elsif ex.is_a?(Hash)
          item.merge!(ex)
          if msg.is_a?(Exception)
            set_exc(item, msg)
          else
            item[:msg] = msg.to_s
          end
        end
      elsif msg        # 3 args
        set_exc(item, ex) if ex.is_a?(Exception)
        item.merge!(data) if data.is_a?(Hash)
        item[:msg] = msg.to_s
      else             # No args
        item[:msg] = @default_message
      end
      item
    end

    def set_exc(item, exc)
      item[@exc_key] = @formatter.serialize_exc(exc)
    end
  end
end
