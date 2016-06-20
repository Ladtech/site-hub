# rubocop:disable Metrics/ClassLength
class SiteHub
  describe Request do
    HttpHeaderKeys = Constants::HttpHeaderKeys
    RackHttpHeaderKeys = Constants::RackHttpHeaderKeys

    include_context :rack_request
    include_context :http_proxy_rules

    let(:rack_env) { env_for(method: :get) }

    subject(:request) do
      described_class.new(env: rack_env)
    end

    describe '#initialize' do
      it 'sets the time' do
        time = Time.now
        expect(subject.time).to eq(time)
      end
    end

    describe '#map' do
      it 'sets mapped_url and mapped_path' do
        subject.map(:path, :url)
        expect(subject.mapped_path).to be(:path)
        expect(subject.mapped_url).to be(:url)
      end
    end

    describe '#request_method' do
      let(:rack_env) { env_for(method: :get) }

      it_behaves_like 'a memoized helper'

      it 'returns the request method' do
        expect(subject.request_method).to be(:get)
      end
    end

    describe '#body' do
      it_behaves_like 'a memoized helper'

      let(:rack_env) { env_for(method: :post, params_or_body: 'body') }
      it 'returns the request body' do
        expect(subject.body).to eq('body')
      end
    end

    describe '#headers' do
      it_behaves_like 'prohibited_header_filter' do
        let(:rack_env) { format_http_to_rack_headers(prohibited_headers.merge(permitted_header => 'value')) }
        subject do
          request.headers
        end
      end

      it_behaves_like 'a memoized helper'

      let(:x_forwarded_host) { HttpHeaderKeys::X_FORWARDED_HOST_HEADER }

      context 'x-forwarded-host header' do
        context 'header not present' do
          it 'assigns it to the requested host' do
            expect(subject.headers[x_forwarded_host]).to eq('example.org')
          end
        end

        context 'header already present' do
          let(:rack_env) { env_for(env: { format_as_rack_header_name(x_forwarded_host) => 'first.host,second.host' }) }

          it 'appends the host to the existing value' do
            expect(subject.headers[x_forwarded_host]).to eq('first.host,second.host,example.org')
          end
        end
      end

      # used for identifying the originating IP address of a request.
      context 'x-forwarded-for' do
        let(:x_forwarded_for) { HttpHeaderKeys::X_FORWARDED_FOR_HEADER }

        context 'header not present' do
          it 'introduces it assigned to the value the remote-addr http header' do
            expect(subject.headers[x_forwarded_for]).to eq(rack_env['REMOTE_ADDR'])
          end
        end

        context 'already present' do
          let(:rack_env) { env_for(env: { format_as_rack_header_name(x_forwarded_for) => 'first_host_ip' }) }

          it 'appends the value of the remote-addr header to it' do
            expect(subject.headers[x_forwarded_for]).to eq("first_host_ip,#{rack_env['REMOTE_ADDR']}")
          end
        end
      end
    end

    describe '#mapping' do
      it_behaves_like 'a memoized helper'

      it 'returns a RequestMapping' do
        mapped_url = 'source_url'
        mapped_path = 'mapped_path'
        subject.map(mapped_path, mapped_url)

        expected_mapping = RequestMapping.new(source_url: subject.url, mapped_url: mapped_url, mapped_path: mapped_path)
        expect(subject.mapping).to eq(expected_mapping)
      end
    end

    describe '#mapped?' do
      it_behaves_like 'a memoized helper'

      context 'request has been mapped' do
        it 'returns true' do
          subject.map('mapped_path', 'mapped_url')

          expect(subject.mapped?).to eq(true)
        end
      end

      context 'request has not been mapped' do
        it 'returns false' do
          expect(subject.mapped?).to eq(false)
        end
      end
    end

    describe '#remote_user' do
      let(:rack_env) { env_for(env: { 'REMOTE_USER' => 'user' }) }
      it 'returns the value of REMOTE_USER rack header' do
        expect(subject.remote_user).to eq('user')
      end
    end

    describe '#transation_id' do
      let(:transaction_id) { HttpHeaderKeys::TRANSACTION_ID }
      let(:rack_env) { env_for(env: { format_as_rack_header_name(transaction_id) => :transaction_id }) }

      it 'returns the value of transaction_id header' do
        expect(subject.transaction_id).to eq(:transaction_id)
      end
    end

    describe '#http_version' do
      let(:http_version) { RackHttpHeaderKeys::HTTP_VERSION }
      let(:rack_env) { env_for(env: { http_version => :version }) }

      it 'returns the value of http_version header' do
        expect(subject.http_version).to eq(:version)
      end
    end

    describe '#source_address' do
      context 'x-forwarded-for header set' do
        let(:x_forwarded_for) { HttpHeaderKeys::X_FORWARDED_FOR_HEADER }
        let(:address) { 'first_host_ip' }
        let(:rack_env) { env_for(env: { format_as_rack_header_name(x_forwarded_for) => address }) }

        it 'appends the value of the remote-addr header to it' do
          expect(subject.source_address).to eq(address)
        end
      end

      context 'x-forwarded-for header not set' do
        it 'returns REMOTE_ADDR' do
          expect(subject.source_address).to eq(rack_env['REMOTE_ADDR'])
        end
      end
    end

    describe '#url' do
      it_behaves_like 'a memoized helper'

      it 'returns the source url' do
        expect(subject.url).to eq(subject.rack_request.url)
      end
    end

    describe '#params' do
      it_behaves_like 'a memoized helper'

      let(:params) { { 'param' => 'value' } }
      let(:rack_env) { env_for(params_or_body: params) }
      it 'returns the request params' do
        expect(subject.params).to eq(params)
      end
    end

    describe '#path' do
      it_behaves_like 'a memoized helper'

      let(:path) { '/path' }
      let(:rack_env) { env_for(path: path) }
      it 'returns the request path' do
        expect(subject.path).to eq(path)
      end
    end

    describe '#query_string' do
      it_behaves_like 'a memoized helper'

      let(:query_string) { 'param=value' }
      let(:rack_env) { env_for(path: "/?#{query_string}") }
      it 'returns the request path' do
        expect(subject.query_string).to eq(query_string)
      end
    end
  end
end
