Rabl.configure do |config|
  config.include_json_root = true
  config.include_child_root = true

  # Motivation here it make it call as_json when rendering timestamps
  # and therefore display miliseconds. Otherwise it would fall to
  # JSON.dump which doesn't display the miliseconds
  config.json_engine = ActiveSupport::JSON
end
