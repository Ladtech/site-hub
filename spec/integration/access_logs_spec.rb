require 'cgi'

describe 'access_logs' do
  let(:downstream_url) { 'http://localhost:12345/experiment1' }

  let(:experiment_body_1) { 'experiment1_body' }

  let(:access_logger) { StringIO.new }

  before do
    WebMock.enable!
  end

  let(:app) do
    downstream_url = downstream_url()
    access_logger = access_logger()

    sitehub = SiteHub.build do
      access_logger access_logger
      error_logger StringIO.new

      proxy '/endpoint' do
        split(label: :experiment1, percentage: 100) do
          split percentage: 100, label: 'variant1', url: downstream_url
        end
      end
    end
    Async::Middleware.new(sitehub)
  end

  let(:query_string) { '' }
  let(:request_url) { "/endpoint#{query_string.empty? ? '' : "?#{query_string}"}" }

  before do
    query_string_hash = CGI.parse(query_string).collect { |key, value| [key, value.first] }.to_h
    stub_request(:get, downstream_url).with(query: query_string_hash)
    get(request_url)
  end

  subject do
    access_logger.string
  end

  context 'query string' do
    context 'present' do
      let(:query_string) { 'key=value' }
      it 'logs it' do
        expect(subject).to include("GET #{request_url} => #{downstream_url}")
      end
    end

    context 'not present' do
      let(:query_string) { '' }
      it 'is not logged' do
        expect(subject).to match(/"GET\s#{request_url}\s=>\s#{downstream_url}\s/)
        expect(subject).to include(query_string)
      end
    end
  end

  module WebMock
    def self.last_request
      WebMock::RequestRegistry.instance.requested_signatures.hash.keys.first
    end
  end

  it 'logs the transaction id' do
    expected_id = WebMock.last_request.headers['Sitehub-Transaction-Id']
    expect(subject).to match(/transaction_id:#{expected_id}/)
  end

  it 'logs the response status' do
    expect(subject).to include('200')
  end

  it 'logs the downstream url that was proxied to' do
    expect(subject).to include("#{request_url} => #{downstream_url}")
  end

  it 'has the required format' do
    processing_time_matcher = '\d{1}\.\d{4}'
    transaction_id_matcher = '[a-z\d]+'
    expected_response_status = 200
    expect(subject).to match(/transaction_id:#{transaction_id_matcher}:\s"GET\s#{request_url}\s=>\s#{downstream_url}\s"\s#{expected_response_status}\s-\s#{processing_time_matcher}/)
  end
end
