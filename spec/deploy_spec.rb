require "yaml"
require "fileutils"
require "minitest/autorun"
require "#{File.expand_path(File.dirname(__FILE__))}/../lib/traquitana.rb"

describe Traquitana::Deployer do
   before do
      @config = Traquitana::Config.instance
      @deploy = Traquitana::Deployer.new 
   end
end
