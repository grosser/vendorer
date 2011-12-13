require 'spec_helper'

describe Vendorer do
  before do
    `rm -rf spec/tmp`
    `mkdir spec/tmp`
  end

  after do
    `rm -rf spec/tmp`
  end

  def write(file, content)
    File.open("spec/tmp/#{file}",'w'){|f| f.write(content) }
  end

  def read(file)
    File.read("spec/tmp/#{file}")
  end

  def ls(path)
    `ls spec/tmp/#{path}`.split("\n")
  end

  def run
    out = `cd spec/tmp && bundle exec ../../bin/vendorer`
    raise out unless $?.success?
  end

  it "has a VERSION" do
    Vendorer::VERSION.should =~ /^[\.\da-z]+$/
  end

  it "can download a file" do
    write 'Vendorfile', "file 'public/javascripts/jquery.min.js' => 'http://code.jquery.com/jquery-latest.min.js'"
    run
    ls('public/javascripts').should == ["jquery.min.js"]
    read('public/javascripts/jquery.min.js').should include('jQuery')
  end
end
