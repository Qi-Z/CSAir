require 'json'
tempHash = {
    "key_a" => "val_a",
    "key_b" => "val_b"
}
File.open("temp.json","w") do |f|
  f.write({}.to_json)
end