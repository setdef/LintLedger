# frozen_string_literal: true

module Alibi
  class AlibiFileReader
    def initialize(path)
      @path = path
      freeze
    end

    def bytes
      File.binread(@path)
    rescue SystemCallError => e
      # Ruby follows the system's reason with " @ rb_sysopen - PATH", which means nothing to someone who ran alibi.
      raise(Error, "can't read the alibi file: #{e.message.partition(' @ ').first.downcase}")
    end
  end
end
