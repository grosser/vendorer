require 'spec_helper'

describe Vendorer do
  it "has a VERSION" do
    Vendorer::VERSION.should =~ /^[\.\da-z]+$/
  end
end
