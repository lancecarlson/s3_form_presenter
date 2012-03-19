require 'json'
require 'base64'
require 'openssl'

module S3FormPresenter
  class Form
    HIDDEN_FIELD_NAMES = :key, :access_key, :acl, :redirect_url, :policy, :signature
    ACCESSOR_FIELDS = HIDDEN_FIELD_NAMES - [:policy, :signature]
    RENAMED_FIELDS = {:redirect_url => "success_action_redirect", :access_key => "AWSAccessKeyId"}
    REQUIRED_ATTRIBUTES = [:bucket, :secret_key] + HIDDEN_FIELD_NAMES
    attr_accessor :bucket, :secret_key, :inner_content, :extra_form_attributes, :starts_with

    def initialize(key, redirect_url, options={}, &block)
      @key = key
      @access_key = options[:access_key] || ENV["AWS_ACCESS_KEY_ID"]
      @secret_key = options[:secret_key] || ENV["AWS_SECRET_ACCESS_KEY"]
      @bucket = options[:bucket] || ENV["AWS_S3_BUCKET"]
      @acl = options[:acl] || :private
      @extra_form_attributes = options[:extra_form_attributes]
      @redirect_url = redirect_url
      if block_given?
        @inner_content = block.call
      else
        @inner_content = %Q(<input name="file" type="file"><input type="submit" value="Upload File" class="btn btn-primary">)
      end
      generate_hidden_field_accessors
    end

    def header
      %Q(<form action="https://#{bucket}.s3.amazonaws.com/" method="post" enctype="multipart/form-data"#{extra_form_attributes}>)
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
      name = RENAMED_FIELDS[name] || name
      %Q(<input type="hidden" name="#{name}" value="#{value}">)
    end

    def to_html
      validate_required
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
                         ["starts-with", "$key", "#{starts_with}"],
                         {"acl" => acl},
                         {"success_action_redirect" => redirect_url}
                        ]
      }
    end

    def starts_with
      dirs = key.split("/")
      dirs.pop
      dirs.join("/")
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

    def validate_required
      REQUIRED_ATTRIBUTES.each do |attr|
        raise "#{attr} has not been specified." unless send(attr)
      end
    end
  end
end
