class Vendorer
  def initialize(options)
    @options = options
    eval(File.read('Vendorfile'))
  end

  private

  def file(options)
    options.each do |file, url|
      update_or_not file do
        run "mkdir -p #{File.dirname(file)}"
        run "curl '#{url}' -o #{file}"
        raise "Downloaded empty file" unless File.exist?(file)
      end
    end
  end

  def folder(options)
    options.each do |path, url|
      update_or_not path do
        run "mkdir -p #{File.dirname(path)}"
        run "git clone '#{url}' #{path}"
        run "rm -rf #{path}/.git"
      end
    end
  end

  def update_or_not(path)
    if @options[:update] or not File.exist?(path)
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
