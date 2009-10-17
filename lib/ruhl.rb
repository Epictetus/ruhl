$:.unshift File.dirname(__FILE__)

require 'nokogiri'
require 'logger'
require 'ruhl/engine'
require 'ruhl/errors'

module Ruhl
  class << self
    attr_accessor :logger
  end

  self.logger = Logger.new(STDOUT)

end
