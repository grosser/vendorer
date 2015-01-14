require 'spec_helper'
require 'tmpdir'

describe Vendorer do
  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir, &example)
    end
  end

  def write(file, content)
    File.open(file, 'w') { |f| f.write(content) }
  end

  def read(file)
    File.read(file)
  end

  def size(file)
    File.size(file)
  end

  def run(cmd)
    result = `#{cmd} 2>&1`
    raise result unless $?.success?
    result
  end

  def ls(path)
    `ls #{path} 2>&1`.split("\n")
  end

  def vendorer(args='', options={})
    out = `#{Bundler.root}/bin/vendorer #{args} 2>&1`
    raise out if $?.success? == !!options[:raise]
    out
  end

  it "has a VERSION" do
    Vendorer::VERSION.should =~ /^[\.\da-z]+$/
  end

  describe 'version' do
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

  it "can use Vendorfile.rb" do
    write 'Vendorfile.rb', "file 'public/javascripts/jquery.min.js', 'http://code.jquery.com/jquery-latest.min.js'"
    vendorer
    read('public/javascripts/jquery.min.js').should include('jQuery')
  end

  describe '#file' do
    def simple_vendorfile
      write 'Vendorfile', "file 'public/javascripts/jquery.min.js', 'http://code.jquery.com/jquery-latest.min.js'"
    end

    it "can download a new file" do
      simple_vendorfile
      vendorer
      ls('public/javascripts').should == ["jquery.min.js"]
      read('public/javascripts/jquery.min.js').should include('jQuery')
    end

    it "cannot download a missing file" do
      write 'Vendorfile', "file 'public/javascripts/jquery.min.js', 'http://code.jquery.com/sdfsddsfdsfdsf'"
      vendorer '', :raise => true
    end

    it "can download a file via redirect" do
      # old github raw urls are redirected
      write 'Vendorfile', "file 'xxx', 'http://raw.github.com/grosser/vendorer/master/Gemfile'"
      vendorer
      read('xxx').should include('rspec')
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
      raise result unless result.include?("NOTFOUND") or result.include?('Downloaded empty file')
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
        lambda {
          vendorer 'update'
        }.should_not change { run('ls -l public/javascripts').split("\n") }
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

    context "with a compressed resource" do
      def vendorfile_for_compressed_resource
        write 'Vendorfile', "file 'public/javascripts/highcharts.js', 'http://code.highcharts.com/highcharts.js'"
      end

      it "decompresses to plain text" do
        vendorfile_for_compressed_resource
        vendorer
        read('public/javascripts/highcharts.js').should include('Highcharts')
      end
    end
  end

  describe '#folder' do
    before do
      write 'Vendorfile', "folder 'its_recursive', '#{Bundler.root}/.git'"
    end

    it "can download from remote" do
      write 'Vendorfile', "folder 'vendor/plugins/parallel_tests', 'https://github.com/grosser/parallel_tests.git'"
      vendorer
      ls('vendor/plugins').should == ["parallel_tests"]
      read('vendor/plugins/parallel_tests/Gemfile').should include('cucumber')
    end

    it "reports errors when the Vendorfile is broken" do
      write 'Vendorfile', "folder 'vendor/plugins/parallel_tests', 'https://blob'"
      output = vendorer '', :raise => true
      # different errors on travis / local
      raise unless output.include?('Connection refused') or output.include?('resolve host')
    end

    it "can download from local" do
      vendorer
      ls('').should =~ ["its_recursive", "Vendorfile"]
      read('its_recursive/Gemfile').should include('rake')
    end

    it "can handle a trailing slash" do
      write 'Vendorfile', "folder 'its_recursive/', '#{Bundler.root}/.git'"
      output = vendorer
      ls('').should =~ ["its_recursive", "Vendorfile"]
      read('its_recursive/Gemfile').should include('rake')
      output.should_not include('//')
    end

    it "does not keep .git folder so everything can be checked in" do
      vendorer
      ls('its_recursive/.git').first.should =~ /cannot access|No such file or directory/
    end

    it "does not update an existing folder" do
      vendorer
      write('its_recursive/Gemfile', 'Foo')
      vendorer
      read('its_recursive/Gemfile').should == 'Foo'
    end

    describe '#update' do
      it "updates a folder" do
        vendorer
        write('its_recursive/Gemfile', 'Foo')
        vendorer 'update'
        read('its_recursive/Gemfile').should include('rake')
      end

      it "can update a specific folder" do
        write 'Vendorfile', "
          folder 'its_recursive', '#{Bundler.root}/.git'
          folder 'its_really_recursive', '#{Bundler.root}/.git'
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
        write 'Vendorfile', "folder 'its_recursive', '#{Bundler.root}/.git', :ref => 'b1e6460'"
        vendorer
        read('its_recursive/Readme.md').should include('CODE EXAMPLE')
      end

      it "can checkout by :branch" do
        write 'Vendorfile', "folder 'its_recursive', '#{Bundler.root}/.git', :branch => 'b1e6460'"
        vendorer
        read('its_recursive/Readme.md').should include('CODE EXAMPLE')
      end

      it "can checkout by :tag" do
        write 'Vendorfile', "folder 'its_recursive', '#{Bundler.root}/.git', :tag => 'b1e6460'"
        vendorer
        read('its_recursive/Readme.md').should include('CODE EXAMPLE')
      end
    end

    context "with an execute after update block" do
      before do
        write 'Vendorfile', "folder('its_recursive', '#{Bundler.root}/.git'){|path| puts 'THE PATH IS ' + path }"
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
        write('public/javascripts/jquery.js', 'Foo')
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
        write('public/javascripts/jquery.js', 'Foo')
        write('xxx.js', 'Foo')
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

      it "can handle trailing slash" do
        write 'Vendorfile', read('Vendorfile').sub("javascripts' do", "javascripts/' do")
        output = vendorer
        read('public/javascripts/jquery.js').should include('jQuery')
        output.should_not include('//')
      end
    end

    context "submodules" do
      def create_git_repo(folder, command)
        # create a git repo with a submodule
        run "mkdir #{folder}"
        run "cd #{folder} && git init"
        run "cd #{folder} && #{command}"
        run "cd #{folder} && git add ."
        run "cd #{folder} && git commit -am 'initial'"
      end

      let(:vendorer) {
        v = Vendorer.new
        def v.puts(x) # silence
        end
        v
      }

      it "installs submodules" do
        create_git_repo 'a', "git submodule add #{Bundler.root}/.git sub"

        vendorer.folder 'plugin', 'a/.git'

        run("ls -a plugin").should == ".\n..\n.gitmodules\nsub\n"
        run("ls -a plugin/sub").should include('Gemfile')
      end

      it "installs recursive submodules" do
        create_git_repo 'a', "git submodule add #{Bundler.root}/.git sub_a"
        create_git_repo 'b', 'git submodule add `cd ../a/.git && pwd` sub_b'

        vendorer.folder 'plugin', 'b/.git'

        run("ls -a plugin").should == ".\n..\n.gitmodules\nsub_b\n"
        run("ls -a plugin/sub_b").should == ".\n..\n.git\n.gitmodules\nsub_a\n"
        run("ls -a plugin/sub_b/sub_a").should include('Gemfile')
      end

      it "installs recursive submodules from a branch" do
        create_git_repo 'a', "git submodule add #{Bundler.root}/.git sub_a"
        create_git_repo 'b', 'touch .gitmodules'

        # create submodules on a branch
        run "cd b && git checkout -b with_submodules"
        run "cd b && git submodule add `cd ../a/.git && pwd` sub_b"
        run "cd b && git add . && git commit -am 'submodules'"
        run "cd b && git checkout master"

        vendorer.folder 'plugin', 'b/.git', :branch => 'with_submodules'

        run("ls -a plugin").should == ".\n..\n.gitmodules\nsub_b\n"
        run("ls -a plugin/sub_b").should == ".\n..\n.git\n.gitmodules\nsub_a\n"
        run("ls -a plugin/sub_b/sub_a").should include('Gemfile')
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

    it "fails with a nice backtrace" do
      write 'Vendorfile', "\n\nfile 'XXX'\n\n"
      output = vendorer '', :raise => true
      output.should include("from Vendorfile:3:in `parse")
    end
  end

  describe "#init" do
    it "creates a Vendorfile via cli" do
      vendorer("init")
      read("Vendorfile").should include("folder")
    end

    context "from ruby" do
      before do
        Dir.chdir '../../' if RUBY_VERSION < '1.9'
      end

      it "creates a Vendorfile via ruby" do
        Vendorer.new('init').init
        read("Vendorfile").should include("folder")
      end

      it "created Vendorfile contains commented out examples" do
        Vendorer.new('init').init
        read("Vendorfile").split("\n").each { |l| l.should =~ /^(#|\s*$)/ }
      end

      it "created Vendorfile contains many examples" do
        Vendorer.new('init').init
        read("Vendorfile").should include("folder 'vendor/")
        read("Vendorfile").should include("file 'vendor/")
        read("Vendorfile").should include("rewrite(path)")
      end

      it "created Vendorfile does not contain other instructions" do
        Vendorer.new('init').init
        read("Vendorfile").should_not include("vendorer init")
        read("Vendorfile").should_not include("Gemfile")
        read("Vendorfile").should_not include("gem install")
        read("Vendorfile").should_not include("```")
      end
    end
  end

  describe "#from" do
    it "returns to normal after the block" do
      write "Vendorfile", "
        from '#{Bundler.root}/.git' do
          file 'Readme.md'
        end
        file 'jquery.js', 'http://code.jquery.com/jquery-latest.min.js'
      "
      vendorer
      ls(".").should =~ ['Readme.md', 'Vendorfile', 'jquery.js']
      read('jquery.js').should include("jQuery")
    end

    it "can checkout a specific version" do
      write "Vendorfile", "
          from '#{Bundler.root}/.git', :tag => 'v0.1.0' do
            file 'lib/vendorer/version.rb'
          end
        "
      vendorer
      read('lib/vendorer/version.rb').should include("0.1.0")
    end

    it "passes the path to the working copy to the block" do
      write "Vendorfile", "
          from('#{Bundler.root}/.git'){|path| puts `ls #\{path}` }
        "
      vendorer.should include('vendorer.gemspec')
    end

    context "with file" do
      it "copies" do
        write "Vendorfile", "
          from '#{Bundler.root}/.git' do
            file 'Readme.md'
          end
        "
        vendorer
        ls(".").should =~ ['Readme.md', 'Vendorfile']
      end

      it "copies to/from a nested location" do
        write "Vendorfile", "
          from '#{Bundler.root}/.git' do
            file 'foo/bar/renamed.rb', 'lib/vendorer.rb'
          end
        "
        vendorer
        ls(".").should =~ ['foo', 'Vendorfile']
        ls("./foo/bar").should =~ ['renamed.rb']
      end

      it "renames" do
        write "Vendorfile", "
          from '#{Bundler.root}/.git' do
            file 'Readme.renamed', 'Readme.md'
          end
        "
        vendorer
        ls(".").should =~ ['Readme.renamed', 'Vendorfile']
      end
    end

    context "with folder" do
      it "copies" do
        write "Vendorfile", "
          from '#{Bundler.root}/.git' do
            folder 'lib'
          end
        "
        vendorer
        ls(".").should =~ ['lib', 'Vendorfile']
        ls("./lib").should =~ ['vendorer', 'vendorer.rb']
      end

      it "copies to/from a nested location" do
        write "Vendorfile", "
          from '#{Bundler.root}/.git' do
            folder 'foo/bar', 'lib/vendorer'
          end
        "
        vendorer
        ls(".").should =~ ['foo', 'Vendorfile']
        ls("./foo/bar").should =~ ['version.rb']
      end

      it "renames" do
        write "Vendorfile", "
          from '#{Bundler.root}/.git' do
            folder 'foo', 'lib'
          end
        "
        vendorer
        ls(".").should =~ ['foo', 'Vendorfile']
        ls("./foo").should =~ ['vendorer', 'vendorer.rb']
      end
    end

    context "with folder nesting" do
      it "copies" do
        write "Vendorfile", "
          folder 'foo' do
            from '#{Bundler.root}/.git' do
              folder 'lib'
              file 'Gemfile'
            end
          end
        "
        vendorer
        ls(".").should =~ ['foo', 'Vendorfile']
        ls("./foo").should =~ ['Gemfile', 'lib']
        ls("./foo/lib").should =~ ['vendorer', 'vendorer.rb']
      end
    end

    it "gives 'not found' error for non-existent file" do
      write "Vendorfile", "
        from '#{Bundler.root}/.git', :tag => 'b1e6460' do
          file 'bogus'
        end
      "
      output = vendorer '', :raise => true
      output.should include("'bogus' not found in #{Bundler.root}/.git")
    end
  end
end
