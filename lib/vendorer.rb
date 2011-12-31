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
      run "curl -L '#{url}' -o #{path}"
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
