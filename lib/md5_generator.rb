require "digest"

module Md5Generator
  def self.generate(content)
    Digest::MD5.hexdigest content
  end
end