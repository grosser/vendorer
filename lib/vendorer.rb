class Vendorer
  def initialize(options)
    @options = options
    eval(File.read('Vendorfile'))
  end

  private

  def file(options)
    options.each do |file, url|
      update_or_not file do
        `mkdir -p #{File.dirname(file)}`
        `curl --silent '#{url}' > #{file}`
      end
    end
  end

  def folder(options)
    options.each do |path, url|
      update_or_not path do
        `mkdir -p #{File.dirname(path)}`
        `git clone '#{url}' #{path}`
        `rm -rf #{path}/.git`
      end
    end
  end

  def update_or_not(path)
    if @options[:update] or not File.exist?(path)
      puts "updating #{path}"
      `rm -rf #{path}`
      yield
    else
      puts "keeping #{path}"
    end
  end
end
