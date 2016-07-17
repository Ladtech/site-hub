require 'stringio'
shared_context :site_hub do
  let(:downstream_url) { 'http://localhost:12345' }

  before do
    stub_request(:get, downstream_url).to_return(body: 'hello')
  end

  let(:builder) do
    SiteHub::Builder.new.tap do |builder|
      builder.access_logger StringIO.new
      builder.error_logger StringIO.new
      downstream_url = downstream_url()
      builder.proxy '/endpoint' do
        split(label: :label, percentage: 100) do
          split percentage: 50, label: 'experiment1', url: downstream_url
          split percentage: 50, label: 'experiment2', url: downstream_url
        end
      end
    end
  end

  let(:rack_application) do
    builder.build
  end

  let :app do
    rack_application
  end
end
