## S3 Form Presenter

Generates a simple form that is compatible with S3's form API. You can upload S3 assets directly to S3 without hitting your server.

## Usage

```ruby
<% S3FormPresenter::Form.new("some/key/path.ext") do %>
  <input name="file" type="file">
	<input type="submit" value="Save File">
<% end %>
```ruby

## Sinatra Integration (this will be put in a module one day)

```ruby
helpers do
  def s3_form(*args, &block)
    buff = capture_erb(*args, &block)
    form = S3FormPresenter::Form.new(*args)
    form.inner_content = buff
    @_out_buf << form.to_html
  end

  def capture_erb(*args, &block)
    erb_with_output_buffer { block_given? && block.call(*args) }
  end

  def erb_with_output_buffer(buf = '') #:nodoc:
    @_out_buf, old_buffer = buf, @_out_buf
    yield
    @_out_buf
  ensure
    @_out_buf = old_buffer
  end
end
```ruby
