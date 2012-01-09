require 'tempfile'

class Vendorer
  def initialize(options={})
    @options = options
    @sub_path = []
  end

  def parse(content)
    eval(content)
  end

  def file(path, url)
    path = complete_path(path)
    update_or_not path do
      run "mkdir -p #{File.dirname(path)}"
      run "curl '#{url}' -L -o #{path}"
      raise "Downloaded empty file" unless File.exist?(path)
      yield path if block_given?
    end
  end

  def folder(path, url=nil, options={})
    if url
      path = complete_path(path)
      update_or_not path do
        run "rm -rf #{path}"
        run "mkdir -p #{File.dirname(path)}"
        run "git clone '#{url}' #{path}"
        if commit = (options[:ref] || options[:tag] || options[:branch])
          run "cd #{path} && git checkout '#{commit}'"
        end
        run("cd #{path} && git submodule update --init --recursive")
        run "rm -rf #{path}/.git"
        yield path if block_given?
      end
    else
      @sub_path << path
      yield
      @sub_path.pop
    end
  end

  def rewrite(path)
    content = File.read(path)
    result = yield content
    File.open(path,'w'){|f| f.write(result) }
  end

  def init
      vendor_content = %s[# Example Vendorfile
# file 'vendor/assets/javascripts/jquery.min.js', 'http://code.jquery.com/jquery-latest.min.js'
# folder 'vendor/plugins/parallel_tests', 'https://github.com/grosser/parallel_tests.git'

# Execute a block after updates
# file 'vendor/assets/javascripts/jquery.js', 'http://code.jquery.com/jquery.js' do |path|
#   puts "Do something useful with #{path}"
#   rewrite(path) { |content| content.gsub(/\r\n/, \n).gsub /\t/, ' ' }
# end

# Checkout a specific :ref/:tag/:branch
# folder 'vendor/plugins/parallel_tests', 'https://github.com/grosser/parallel_tests.git', :tag => 'v0.6.10'

# DRY folders
# folder 'vendor/assets/javascripts' do
#   file 'jquery.js', 'http://code.jquery.com/jquery-latest.js'
# end]
    File.open('Vendorfile', 'w') do |file|
      file.write(vendor_content)
    end
  end

  private

  def update_or_not(path)
    update_requested = (@options[:update] and (@options[:update] == true or path.start_with?(@options[:update]+'/') or path == @options[:update]))
    if update_requested or not File.exist?(path)
      puts "updating #{path}"
      yield
    else
      puts "keeping #{path}"
    end
  end

  def run(cmd)
    output = ''
    IO.popen(cmd + ' 2>&1') do |pipe|
      while line = pipe.gets
        output << line
      end
    end
    raise output unless $?.success?
  end

  def complete_path(path)
    (@sub_path + [path]).join('/')
  end
end
