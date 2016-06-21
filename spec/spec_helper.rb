require_relative '../lib/gta_scm'

def binary(hex_string)
  hex_string.downcase.gsub(/[^0-9a-f]/,'').split(/(..)/).reject(&:blank?).map{|h| h.to_i(16).chr}.join
end

RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate
end

require 'rspec/support/object_formatter'
module RSpec::Support::ObjectFormatter
  def self.format(obj)
    if obj.is_a?(GtaScm::Node::Base)
      obj.inspect
    elsif obj.nil?
      "nil"
    else
      super(obj)
    end
  end
end