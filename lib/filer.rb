require "filer/version"
require 'filer/watcher'
require "yaml"
require "thor"
require "configliere"

module Filer
  CONFIG = '.filer.yml'

  class Command < Thor

    no_commands do
      def watcher
        Watcher.instance(Settings)
      end
      
      def save_settings
        Settings.save!(CONFIG)
      end
      
      def s3
        params = [:s3_key, :s3_secret, :s3_bucket].map {|m| Settings[m]}
        unless params.compact.size == 3
          puts "Please run filer configure-s3 first"
          exit
        end
        @s3 ||= Filer::S3.new(*params)
      end
    end

    desc "start-watching", "start watching configured directories"
    def start_watching
      watcher.daemonize!
      watcher.start!
    end

    desc "stop-watching", "stop watching configured directories"
    def stop_watching
      watcher.stop!
    end

    desc "directories", "List directories currently handled by filer"
    def directories
      Settings[:directories].each_with_index do |dir, i|
        puts "#{i+1}) #{dir}"
      end
    end

    desc "add-directory", "Adds a directory to be handled by filer"
    def add_directory(dir)
      Settings[:directories].push(dir)
      save_settings
    end

    desc "remove-directory", "Removes directory with given index. Index is taken from " <<
                           "output of filer directories"
    def remove_directory(i)
      Settings[:directories].delete_at(i.to_i-1)
      save_settings
      puts "Updated. New directories: "
      directories
    end

    desc "configure-s3 KEY SECRET BUCKET", 
      "Define key, secret, and bucket to use for s3 " <<
      "upload, eg: filer configure-s3 my_key my_secret my_bucket"
    def configure_s3(key, secret, bucket)
      Settings[:s3_key], Settings[:s3_secret], Settings[:s3_bucket] =
        key, secret, bucket
      save_settings
    end

    desc 'search "KEYWORDS"', "Search indexed files"
    def search(keywords)
      results = Filer::Filed.searchable(keywords).all
      if results.empty?
        puts "No results found"
        return
      end
      results.each_with_index do |r, i|
        puts "#{i+1}) #{r.key} - #{r.highlight["attachment"].join(" ... ")}" 
      end
      ix = ask("Index of file to open (q to exit):")
      return unless ix.to_i > 0 && results[ix.to_i - 1]
      s3.open_file(results[ix.to_i - 1].key.first) 
    end

    Settings.read(CONFIG)
    Settings[:directories] ||= []
  end
end
