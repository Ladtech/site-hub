Dir["#{__dir__}/shared_examples/*.rb"].each do |context|
  require context
end
