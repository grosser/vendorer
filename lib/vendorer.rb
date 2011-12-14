class Vendorer
  def initialize(options)
    @options = options
    eval(File.read('Vendorfile'))
  end

  private

  def file(path, url)
    update_or_not path do
      run "mkdir -p #{File.dirname(path)}"
      run "curl '#{url}' -o #{path}"
      raise "Downloaded empty file" unless File.exist?(path)
      yield path if block_given?
    end
  end

  def folder(path, url)
    update_or_not path do
      run "mkdir -p #{File.dirname(path)}"
      run "git clone '#{url}' #{path}"
      run "rm -rf #{path}/.git"
      yield path if block_given?
    end
  end

  def update_or_not(path)
    update_requested = (@options[:update] and (@options[:update] == true or @options[:update] == path))
    if update_requested or not File.exist?(path)
      puts "updating #{path}"
      run "rm -rf #{path}"
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
end
