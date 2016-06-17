require_relative '../lib/gta_scm'

def binary(hex_string)
  hex_string.downcase.gsub(/[^0-9a-f]/,'').split(/(..)/).reject(&:blank?).map{|h| h.to_i(16).chr}.join
end