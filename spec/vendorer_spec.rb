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

  def run(args='')
    out = `cd spec/tmp && bundle exec ../../bin/vendorer #{args} 2>&1`
    raise out unless $?.success?
    out
  end

  it "has a VERSION" do
    Vendorer::VERSION.should =~ /^[\.\da-z]+$/
  end

  it "shows its version via -v" do
    run('-v').should == "#{Vendorer::VERSION}\n"
  end

  it "shows its version via --version" do
    run('--version').should == "#{Vendorer::VERSION}\n"
  end

  it "shows help via -h" do
    run('-h').should include("Usage")
  end

  it "shows help via --help" do
    run('--help').should include("Usage")
  end

  describe '.file' do
    it "can download via hash syntax" do
      write 'Vendorfile', "file 'public/javascripts/jquery.min.js' => 'http://code.jquery.com/jquery-latest.min.js'"
      run
      ls('public/javascripts').should == ["jquery.min.js"]
      read('public/javascripts/jquery.min.js').should include('jQuery')
    end
  end

  describe '.folder' do
    it "can download via hash syntax" do
      write 'Vendorfile', "folder 'vendor/plugins/parallel_tests' => 'https://github.com/grosser/parallel_tests.git'"
      run
      ls('vendor/plugins').should == ["parallel_tests"]
      read('vendor/plugins/parallel_tests/Gemfile').should include('parallel')
    end

    it "can download local repos" do
      write 'Vendorfile', "folder 'its_recursive' => '../../.git'"
      run
      ls('').should == ["its_recursive", "Vendorfile"]
      read('its_recursive/Gemfile').should include('rake')
    end
  end
end
