require 'tempfile'
require 'tmpdir'
require 'shellwords'

class Vendorer
  def initialize(options={})
    @options = options
    @sub_path = []
  end

  def parse(content)
    eval(content, nil, 'Vendorfile', 1)
  end

  def file(path, url=nil)
    target_path = complete_path(path)
    update_or_not target_path do
      run "mkdir", "-p", File.dirname(target_path)
      if @copy_from_url
        copy_from_path(target_path, url || path)
      else
        run "curl", url, "--fail", "-L", "--compressed", "-o", target_path
        raise "Downloaded empty file" unless File.exist?(target_path)
      end
      yield target_path if block_given?
    end
  end

  def folder(path, url=nil, options={})
    if @copy_from_path or url
      target_path = complete_path(path)
      update_or_not target_path do
        run "rm", "-rf", target_path
        run "mkdir", "-p", File.dirname(target_path)
        if @copy_from_path
          copy_from_path(target_path, url || path)
        else
          download_repository(url, target_path, options)
        end
        yield target_path if block_given?
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

  # Creates Vendorfile with examples
  def init
    separator = "<!-- extracted by vendorer init -->"
    readme = File.read(File.expand_path('../../Readme.md', __FILE__))
    examples = readme.split(separator)[1]
    examples.gsub!(/```.*/,'') # remove ``` from readme
    examples = examples.split("\n").map do |l|
      (l.start_with? '#' or l.empty?) ? l : "# #{l}"
    end.join("\n")
    File.open('Vendorfile', 'w') { |f| f.write(examples.strip) }
  end

  def from(url, options={})
    Dir.mktmpdir do |tmpdir|
      download_repository url, tmpdir, options
      @copy_from_url, @copy_from_path = url, tmpdir
      yield(@copy_from_path)
      @copy_from_url = @copy_from_path = nil
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

  def run(*cmd, dir: nil)
    cmd = "#{cmd.shelljoin} 2>&1"
    cmd = ["cd", dir].shelljoin + " && #{cmd}" if dir
    output = `#{cmd}`
    raise "Failed: #{cmd}\n#{output}" unless $?.success?
  end

  def complete_path(path)
    File.join(@sub_path + [path])
  end

  def download_repository(url, to, options)
    run "git", "clone", url, to
    if commit = (options[:ref] || options[:tag] || options[:branch])
      run "git", "checkout", commit, dir: to
    end
    run "git", "submodule", "update", "--init", "--recursive", dir: to
    run "rm", "-rf", ".git", dir: to
  end

  def copy_from_path(dest_path, src_path)
    src_path ||= dest_path
    copy_from = File.join(@copy_from_path, src_path)
    raise "'#{src_path}' not found in #{@copy_from_url}" unless File.exist?(copy_from)
    run "cp", "-Rp", copy_from, dest_path
  end
end
