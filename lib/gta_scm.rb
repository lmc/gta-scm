module GtaScm

end

require 'rubygems'

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/array/grouping'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/json'
require 'binary_search/pure'
require 'elparser'
require 'parallel'

require 'byebug'
alias debugger byebug

# require 'progress_bar'
# require 'gta_scm/progress_bar_ext'

require 'gta_scm/logger'
def GtaScm.logger
  @logger ||= GtaScm::Logger.new(:debug)
end
def logger
  GtaScm.logger
end

require 'gta_scm/byte_array'
require 'gta_scm/types'
require 'gta_scm/scm'
