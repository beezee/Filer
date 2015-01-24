require "fallen"
require "notifier"
require "filer/s3"
require "filer/filed"

module Watcher
  extend Fallen
  FILER_LOG = "filer_watcher.log"

  def self.instance(settings)
    @settings = settings
    Watcher.pid_file 'filer_watcher.pid'
    Watcher.stderr FILER_LOG
    Watcher.stdout FILER_LOG
    self.s3
    self
  end

  def self.s3
    params = [:s3_key, :s3_secret, :s3_bucket].map {|m| @settings[m]}
    unless params.compact.size == 3
      puts "Please run filer configure-s3 first"
      exit
    end
    @s3 ||= Filer::S3.new(*params)
  end

  def self.notify(msg)
    Notifier.notify(
      title: "Filer",
      message: msg)
  end

  def self.run
    begin
      while running?
        dirs_files = @settings[:directories].flat_map do |d| 
          Dir["#{d}/**/*"].reject {|f| File.directory?(f)}.
            map {|f| [d, f]} 
        end
        dirs_files.each do |(d, f)|
          key = @s3.s3_key(d, f)
          @s3.put_file(key, f)
          fd = Filer::Filed.new(
            key: key, 
            attachment: Base64.encode64(File.read(f)))
          fd.save
          File.delete(f)
        end
        self.notify("Processed #{dirs_files.size} files") unless dirs_files.empty?
        sleep 10
      end
    rescue Exception => e
      self.notify("Filer encountered an error. " <<
        "See #{File.dirname(__FILE__)}/#{FILER_LOG}")
      raise e
    end
  end
end
