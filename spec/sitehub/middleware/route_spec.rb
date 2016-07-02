# it 'extends the middleware with Resolver' do
#   subject.build
#   expect(subject.endpoints[:current]).to be_a(Resolver)
# end
#
# it 'extends the middleware with Rules' do
#   subject.build
#   expect(subject.endpoints[:current]).to be_a(Rules)
# end
#
# context 'rule on route' do

#   it 'adds it to the rule to the middleware object' do
#     subject.build
#     expect(subject.endpoints[:current].rule).to eq(rule)
#   end
# end

# context 'recorded routes cookie' do
#   it 'drops a cookie using the name of the sitehub_cookie_name containing the id' do
#     expect(last_response.cookies[:cookie_name.to_s]).to eq(value: :id.to_s, path: mapped_path)
#   end
#
#   context 'cookie already set' do
#     let(:rack_headers) { { 'HTTP_COOKIE' => 'cookie_name=existing_value' } }
#
#     it 'replaces the value as this is the proxy it should stick with' do
#       expect(last_response.cookies[:cookie_name.to_s]).to eq(value: :id.to_s, path: mapped_path)
#     end
#   end
#
#   context 'recorded_routes_cookie_path not set' do
#     it 'sets the path to be the request path' do
#       expect(last_response.cookies[:cookie_name.to_s][:path]).to eq(mapped_path)
#     end
#   end
#
#   context 'recorded_routes_cookie_path set' do
#     let(:expected_path) { '/expected_path' }
#
#     subject(:app) do
#       described_class.new(id: :id,
#                           sitehub_cookie_path: expected_path,
#                           sitehub_cookie_name: :cookie_name,
#                           mapped_path: mapped_path,
#                           mapped_url: mapped_url)
#     end
#
#     it 'is set as the path' do
#       expect(last_response.cookies[:cookie_name.to_s][:path]).to eq(expected_path)
#     end
#   end
# end
