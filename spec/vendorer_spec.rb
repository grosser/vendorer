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

  def size(file)
    File.size("spec/tmp/#{file}")
  end

  def run(cmd)
    result = `cd spec/tmp && #{cmd} 2>&1`
    raise result unless $?.success?
    result
  end

  def ls(path)
    `ls spec/tmp/#{path} 2>&1`.split("\n")
  end

  def vendorer(args='', options={})
    out = `cd spec/tmp && bundle exec ../../bin/vendorer #{args} 2>&1`
    raise out if $?.success? == !!options[:raise]
    out
  end

  describe 'version' do
    it "has a VERSION" do
      Vendorer::VERSION.should =~ /^[\.\da-z]+$/
    end

    it "shows its version via -v" do
      vendorer('-v').should == "#{Vendorer::VERSION}\n"
    end

    it "shows its version via --version" do
      vendorer('--version').should == "#{Vendorer::VERSION}\n"
    end
  end

  describe 'help' do
    it "shows help via -h" do
      vendorer('-h').should include("Usage")
    end

    it "shows help via --help" do
      vendorer('--help').should include("Usage")
    end
  end

  describe '.file' do
    def simple_vendorfile
      write 'Vendorfile', "file 'public/javascripts/jquery.min.js', 'http://code.jquery.com/jquery-latest.min.js'"
    end

    it "can download a new file" do
      simple_vendorfile
      vendorer
      ls('public/javascripts').should == ["jquery.min.js"]
      read('public/javascripts/jquery.min.js').should include('jQuery')
    end

    it "does not update an existing file" do
      simple_vendorfile
      vendorer
      write('public/javascripts/jquery.min.js', 'Foo')
      vendorer
      read('public/javascripts/jquery.min.js').should == 'Foo'
    end

    it "fails with a nice message if the Vendorfile is broken" do
      write 'Vendorfile', "file 'xxx.js', 'http://NOTFOUND'"
      result = vendorer '', :raise => true
      # different errors on travis / local
      raise result unless result.include?("resolve host 'NOTFOUND'") or result.include?('Downloaded empty file')
    end

    describe "with update" do
      it "updates all files when update is called" do
        simple_vendorfile
        vendorer
        write('public/javascripts/jquery.min.js', 'Foo')
        vendorer 'update'
        read('public/javascripts/jquery.min.js').should include('jQuery')
      end

      context "with multiple files" do
        before do
          write 'Vendorfile', "
          file 'public/javascripts/jquery.js', 'http://code.jquery.com/jquery-latest.js'
          file 'public/javascripts/jquery.js.min', 'http://code.jquery.com/jquery-latest.min.js'
          "
          vendorer
          read('public/javascripts/jquery.js').should include('jQuery')
          read('public/javascripts/jquery.js.min').should include('jQuery')

          write('public/javascripts/jquery.js', 'Foo')
          write('public/javascripts/jquery.js.min', 'Foo')
        end

        it "updates a single file when update is called with the file" do
          vendorer 'update public/javascripts/jquery.js.min'
          size('public/javascripts/jquery.js.min').should > 300
          size('public/javascripts/jquery.js').should == 3
        end

        it "does not update a file that starts with the same path" do
          vendorer 'update public/javascripts/jquery.js'
          size('public/javascripts/jquery.js').should > 300
          size('public/javascripts/jquery.js.min').should == 3
        end
      end

      it "does not change file modes" do
        simple_vendorfile
        vendorer
        run 'chmod 711 public/javascripts/jquery.min.js'
        lambda{
          vendorer 'update'
        }.should_not change{ run('ls -l public/javascripts').split("\n") }
      end
    end

    context "with a passed block" do
      before do
        write 'Vendorfile', "file('public/javascripts/jquery.js', 'http://code.jquery.com/jquery-latest.js'){|path| puts 'THE PATH IS ' + path }"
        @output = "THE PATH IS public/javascripts/jquery.js"
      end

      it "runs the block after update" do
        vendorer.should include(@output)
      end

      it "does not run the block when not updating" do
        vendorer
        vendorer.should_not include(@output)
      end
    end
  end

  describe '.folder' do
    before do
      write 'Vendorfile', "folder 'its_recursive', '../../.git'"
    end

    it "can download from remote" do
      write 'Vendorfile', "folder 'vendor/plugins/parallel_tests', 'https://github.com/grosser/parallel_tests.git'"
      vendorer
      ls('vendor/plugins').should == ["parallel_tests"]
      read('vendor/plugins/parallel_tests/Gemfile').should include('parallel')
    end

    it "reports errors when the Vendorfile is broken" do
      write 'Vendorfile', "folder 'vendor/plugins/parallel_tests', 'https://blob'"
      output = vendorer '', :raise => true
      # different errors on travis / local
      raise unless output.include?('Connection refused') or output.include?('resolve host')
    end

    it "can download from local" do
      vendorer
      ls('').should == ["its_recursive", "Vendorfile"]
      read('its_recursive/Gemfile').should include('rake')
    end

    it "does not keep .git folder so everything can be checked in" do
      vendorer
      ls('its_recursive/.git').first.should include('cannot access')
    end

    it "does not update an existing folder" do
      vendorer
      write('its_recursive/Gemfile', 'Foo')
      vendorer
      read('its_recursive/Gemfile').should == 'Foo'
    end

    describe 'update' do
      it "updates a folder" do
        vendorer
        write('its_recursive/Gemfile', 'Foo')
        vendorer 'update'
        read('its_recursive/Gemfile').should include('rake')
      end

      it "can update a specific folder" do
        write 'Vendorfile', "
          folder 'its_recursive', '../../.git'
          folder 'its_really_recursive', '../../.git'
        "
        vendorer
        write('its_recursive/Gemfile', 'Foo')
        write('its_really_recursive/Gemfile', 'Foo')
        vendorer 'update its_recursive'
        size('its_really_recursive/Gemfile').should == 3
        size('its_recursive/Gemfile').should > 30
      end
    end

    describe "git options" do
      it "can checkout by :ref" do
        write 'Vendorfile', "folder 'its_recursive', '../../.git', :ref => 'b1e6460'"
        vendorer
        read('its_recursive/Readme.md').should include('CODE EXAMPLE')
      end

      it "can checkout by :branch" do
        write 'Vendorfile', "folder 'its_recursive', '../../.git', :branch => 'b1e6460'"
        vendorer
        read('its_recursive/Readme.md').should include('CODE EXAMPLE')
      end

      it "can checkout by :tag" do
        write 'Vendorfile', "folder 'its_recursive', '../../.git', :tag => 'b1e6460'"
        vendorer
        read('its_recursive/Readme.md').should include('CODE EXAMPLE')
      end
    end

    context "with an execute after update block" do
      before do
        write 'Vendorfile', "folder('its_recursive', '../../.git'){|path| puts 'THE PATH IS ' + path }"
        @output = 'THE PATH IS its_recursive'
      end

      it "runs the block after update" do
        vendorer.should include(@output)
      end

      it "does not run the block when not updating" do
        vendorer
        vendorer.should_not include(@output)
      end
    end

    context "with folder scoping" do
      before do
        write 'Vendorfile', "
        folder 'public/javascripts' do
          file 'jquery.js', 'http://code.jquery.com/jquery-latest.min.js'
        end
      "
      end

      it "can download a nested file" do
        vendorer
        read('public/javascripts/jquery.js').should include('jQuery')
      end

      it "can update a nested file" do
        vendorer
        write('public/javascripts/jquery.js','Foo')
        vendorer 'update'
        read('public/javascripts/jquery.js').should include('jQuery')
      end

      it "can update a whole folder" do
        write 'Vendorfile', "
        folder 'public/javascripts' do
          file 'jquery.js', 'http://code.jquery.com/jquery-latest.min.js'
        end
        file 'xxx.js', 'http://code.jquery.com/jquery-latest.min.js'
        "
        vendorer
        write('public/javascripts/jquery.js','Foo')
        write('xxx.js','Foo')
        vendorer 'update public/javascripts'
        read('xxx.js').should == "Foo"
        read('public/javascripts/jquery.js').should include('jQuery')
      end

      it "can be nested multiple times" do
        write 'Vendorfile', "
        folder 'public' do
          folder 'javascripts' do
            file 'jquery.js', 'http://code.jquery.com/jquery-latest.min.js'
          end
        end
        "
        vendorer
        read('public/javascripts/jquery.js').should include('jQuery')
      end
    end
  end

  describe '#rewrite' do
    it "can rewrite a file to change stuff" do
      write "Vendorfile", "
      file 'public/javascripts/jquery.min.js', 'http://code.jquery.com/jquery-latest.min.js' do |path|
        rewrite(path){|content| content.gsub('j','h') }
      end
      "
      vendorer
      content = read('public/javascripts/jquery.min.js')[0..100]
      content.should_not include('jQuery')
      content.should include('hQuery')
    end
  end

  describe "#parse" do
    it "executes inside vendorer" do
      $test = 1
      v = Vendorer.new
      v.parse '$test = self'
      $test.should == v
    end
  end
end
