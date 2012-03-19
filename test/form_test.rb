require 'test_helper'

include S3FormPresenter

describe S3FormPresenter::Form do
  before do
    @form = Form.new("some/test/key.ext") do
      %Q(<input name="file" type="file"><input type="submit" value="Upload File" class="btn btn-primary">)
    end
    @form.bucket = "test_bucket"
    @form.access_key = "test_access_key"
    @form.secret_key = "test_secret_key"
    @form.acl = :private
    @form.redirect_url = "http://www.some-test-redirect.com/some/path"
  end

  describe "initializer" do
    it "allows an empty block and provides a sane default" do
      @form = Form.new("some/test/key.ext").inner_content.must_equal %Q(<input name="file" type="file"><input type="submit" value="Upload File" class="btn btn-primary">)
    end

    it "should let you override access_key, secret_key and bucket with ENV" do
      ENV["AWS_ACCESS_KEY_ID"] = "overridden_env_access_key"
      ENV["AWS_SECRET_ACCESS_KEY"] = "overridden_env_secret_key"
      ENV["AWS_S3_BUCKET"] = "overridden_env_bucket"
      @form = Form.new("some/test/key.ext").access_key.must_equal "overridden_env_access_key"
      @form = Form.new("some/test/key.ext").secret_key.must_equal "overridden_env_secret_key"
      @form = Form.new("some/test/key.ext").bucket.must_equal "overridden_env_bucket"
    end

    it "should let you override access_key, secret_key and bucket and acl with options in the initializer" do
      @form = Form.new("some/test/key.ext", :access_key => "overridden_options_access_key").access_key.must_equal "overridden_options_access_key"
      @form = Form.new("some/test/key.ext", :secret_key => "overridden_options_secret_key").secret_key.must_equal "overridden_options_secret_key"
      @form = Form.new("some/test/key.ext", :bucket => "overridden_options_bucket").bucket.must_equal "overridden_options_bucket"
      @form = Form.new("some/test/key.ext", :acl => "overridden_options_acl").acl.must_equal "overridden_options_acl"
    end
  end

  describe "header" do
    it "generates a multi-part post form with the correct path" do
      @form.header.must_equal %Q(<form action="http://test_bucket.s3.amazonaws.com/" method="post" enctype="multipart/form-data">)
    end
  end

  describe "footer" do
    it "generates an ending form tag" do
      @form.footer.must_equal %Q(</form>)
    end
  end

  describe "accessor_fields" do
    it "generates accessors for all accessor_fields after initialize" do
      Form::ACCESSOR_FIELDS.each do |field|
        @form.must_respond_to(field)
        @form.must_respond_to("#{field}=")
      end
    end
  end

  describe "hidden_field" do
    it "generates HTML for a hidden field tag" do
      @form.hidden_field("some_name", "some_value").must_equal %Q(<input type="hidden" name="some_name" value="some_value">)
    end
  end

  describe "hidden_fields" do
    it "generates HTML for each hidden_field" do
      #@form.hidden_fields.must_equal []
    end
  end

  describe "policy_json" do
    it "generates the plain json for the policy" do
      obj = @form.policy_object
      conditions = obj["conditions"]
      obj["expiration"].must_equal (Time.now + (10*60*60)).utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')
      conditions[0]["bucket"].must_equal "test_bucket"
      conditions[1].must_equal ["starts-with", "$key", "some/test/key.ext"]
      conditions[2]["acl"].must_equal :private
      conditions[3]["success_action_redirect"].must_equal "http://www.some-test-redirect.com/some/path"
    end
  end

  describe "policy" do
    it "generates the base64 encoded policy used in the form" do
      @form.policy.length.must_equal 288
    end
  end

  describe "signature" do
    it "generates the signature" do
      @form.signature.length.must_equal 28
    end
  end

  describe "inner_content" do
    it "should grab content from a block if passed" do
      @form.inner_content.must_equal %Q(<input name="file" type="file"><input type="submit" value="Upload File" class="btn btn-primary">)
    end
  end

  describe "to_html" do
    it "generates the full html of the form" do
      content = @form.header + @form.hidden_fields.join + @form.inner_content + @form.footer
      #content = "" # comment out if you want to see real output
      @form.to_html.must_equal content
    end
  end
end
