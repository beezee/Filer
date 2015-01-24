require 'aws-sdk'
require 'tempfile'

module Filer
  class S3
    
    def initialize(key, secret, bucket_name)
      @key, @secret, @bucket_name = key, secret, bucket_name
    end

    def s3_init_params
      { access_key_id: @key, secret_access_key: @secret,
        server_side_encryption: :aes256 }
    end

    def s3
      @s3 ||= AWS::S3.new(s3_init_params)
    end

    def bucket
      return @bucket if @bucket 
      bucket = s3.buckets[@bucket_name]
      unless bucket.location_constraint == s3.config.region
        @s3 = nil
        @s3 = AWS::S3.new(s3_init_params.
          merge(region: bucket.location_constraint))
        bucket = s3.buckets[@bucket_name]
      end
      @bucket = bucket
    end

    def s3_key(source_dir, path)
      filename = File.basename(path, '.*')
      ext = File.extname(path)
      keypath = path.gsub(source_dir, "").
              gsub("#{filename}#{ext}", "").
              gsub(/^\//, "")
      y = Time.now.strftime("%Y")
      m = Time.now.strftime("%m")
      d = Time.now.strftime("%d")
      "#{keypath}#{filename}-#{y}-#{m}-#{d}#{ext}"
    end

    def put_file(key, path)
      o = bucket.objects[key]
      o.write(Pathname.new(path), server_side_encryption: :aes256)
    end

    def open_file(key)
      o = bucket.objects[key]
      filename = File.basename(key)
      ext = File.extname(key)
      t = Tempfile.new([filename, ext])
      o.read do |ch| t.write(ch) end
      t.close
      `open #{t.path}`
    end
  end
end
