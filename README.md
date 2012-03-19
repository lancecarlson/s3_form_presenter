= S3 Form Presenter = 

Generates a simple form that is compatible with S3's form API. You can upload S3 assets directly to S3 without hitting your server.

= Usage =

	<% S3FormPresenter::Form.new("some/key/path.ext") do %>
		 <input name="file" type="file">
		 <input type="submit" value="Save File">
	<% end %>