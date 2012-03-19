require 'json'
require 'base64'
require 'openssl'

module S3FormPresenter
  class Form
    HIDDEN_FIELD_NAMES = :key, :access_key, :secret_key, :acl, :redirect_url, :policy, :signature
    ACCESSOR_FIELDS = HIDDEN_FIELD_NAMES - [:policy, :signature]
    RENAMED_FIELDS = {:redirect_url => "success_action_redirect", :access_key => "AWSAccessKeyId"}
    attr_accessor :bucket, :inner_content

    def initialize(key, options={}, &block)
      @key = key
      @access_key = options[:access_key] || ENV["AWS_ACCESS_KEY_ID"]
      @secret_key = options[:secret_key] || ENV["AWS_SECRET_ACCESS_KEY"]
      @bucket = options[:bucket] || ENV["AWS_S3_BUCKET"]
      @acl = options[:acl]
      if block_given?
        @inner_content = block.call
      else
        @inner_content = %Q(<input name="file" type="file"><input type="submit" value="Upload File" class="btn btn-primary">)
      end
      generate_hidden_field_accessors
    end

    def header
      %Q(<form action="http://#{bucket}.s3.amazonaws.com/" method="post" enctype="multipart/form-data">)
    end

    def footer
      %Q(</form>)
    end

    def hidden_fields
      HIDDEN_FIELD_NAMES.map do |field|
        hidden_field(field, send(field))
      end
    end
    
    def hidden_field(name, value)
      %Q(<input type="hidden" name="#{name}" value="#{value}">)
    end

    def to_html
      content = ""
      content += header
      content += hidden_fields.join
      content += inner_content
      content += footer
    end

    def policy
      Base64.encode64(policy_object.to_json).gsub(/\n|\r/, '')
    end

    def signature
      Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), secret_key, policy)).gsub("\n","")
    end

    def policy_object
      {
        "expiration" => policy_expiration,
        "conditions" => [
                         {"bucket" => bucket},
                         ["starts-with", "$key", "#{key}"],
                         {"acl" => acl},
                         {"success_action_redirect" => redirect_url}
                        ]
      }
    end

    private

    def policy_expiration
      (Time.now + (10*60*60)).utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')
    end

    def generate_hidden_field_accessors
      ACCESSOR_FIELDS.each do |field|
        self.class.send(:attr_accessor, field) unless self.class.respond_to?(field)
      end
    end
  end
end