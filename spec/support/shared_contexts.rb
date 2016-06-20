Dir["#{__dir__}/shared_contexts/*.rb"].each do |context|
  require context
end
