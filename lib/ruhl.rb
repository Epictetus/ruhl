$:.unshift File.dirname(__FILE__)

require 'nokogiri'
require 'logger'
require 'ruhl/engine'
require 'ruhl/errors'

module Ruhl
  class << self
    attr_accessor :logger, :encoding
    attr_accessor :use_instance_variables, :log_instance_variable_warning
  end

  self.logger = Logger.new(STDOUT)

  self.encoding = 'UTF-8'

  self.use_instance_variables = true
  self.log_instance_variable_warning = true
end
