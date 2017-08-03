module GtaScm

end

require 'rubygems'
require 'digest'

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/array/grouping'
require 'active_support/core_ext/object/deep_dup'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/string/strip'
require 'active_support/json'
require 'andand'
require 'binary_search/pure'
require 'elparser'
require 'parallel'

require 'byebug'
alias debugger byebug

require 'progress_bar'
require 'gta_scm/progress_bar_ext'

require 'gta_scm/logger'
def GtaScm.logger
  @logger ||= GtaScm::Logger.new(:debug)
end
def logger
  GtaScm.logger
end
def hex(input)
  input = input.bytes if input.is_a?(String)
  input.map{|val| (val||0).to_s(16).rjust(2,"0")}.join(" ")
end

require 'gta_scm/byte_array'
require 'gta_scm/types'
require 'gta_scm/scm'
