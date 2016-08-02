require 'sitehub/cookie/rewriting'

class SiteHub
  class Cookie
    describe Rewriting do
      include_context :module_spec

      let(:downstream_domain) { '.downstream_domain.com' }

      let(:request_mapping) do
        RequestMapping.new(source_url: 'http://example.org',
                           mapped_url: "http://#{downstream_domain}",
                           mapped_path: '/map')
      end

      let(:substitute_domain) { URI(request_mapping.source_url).host }
      let(:substitute_path) { '/path' }
      let(:downstream_response) { Rack::Response.new }
      let(:downstream_domain_cookie_name) { 'downstream.cookie' }

      before do
        downstream_response.set_cookie(downstream_domain_cookie_name, domain: downstream_domain, value: 'value')
        downstream_response.set_cookie('downstream.cookie2', domain: downstream_domain, value: 'value2', httponly: true)
      end

      describe '#cookies_string_as_hash' do
        it 'returns the string as a hash' do
          cookie_header = downstream_response.headers['Set-Cookie']

          cookie_strings = cookie_header.lines
          first_cookie = SiteHub::Cookie.new(cookie_strings[0])
          second_cookie = SiteHub::Cookie.new(cookie_strings[1])
          expected = {
            first_cookie.name => first_cookie,
            second_cookie.name => second_cookie
          }
          result = subject.cookies_string_as_hash(cookie_header)
          expect(result).to eq(expected)
        end
      end

      describe '#cookies_hash_to_string' do
        it 'returns the hash as a correctly formatted string' do
          cookies_hash = subject.cookies_string_as_hash(downstream_response.headers['Set-Cookie'])
          expect(subject.cookies_hash_to_string(cookies_hash)).to eq(downstream_response.headers['Set-Cookie'])
        end
      end

      describe '#rewrite_cookies' do
        context 'subdomain character present' do
          it 'substitues the domain for the mapped domain' do
            downstream_response.set_cookie(downstream_domain_cookie_name, domain: downstream_domain, value: 'value')
            subject.rewrite_cookies(downstream_response.headers, substitute_domain: substitute_domain)
            expect(downstream_response.cookies[downstream_domain_cookie_name][:domain]).to eq('.example.org')
          end
        end

        context 'subdomain not character present' do
          it 'substitues the domain for the mapped domain' do
            downstream_response.set_cookie(downstream_domain_cookie_name, domain: 'downstream.com', value: 'value')
            subject.rewrite_cookies(downstream_response.headers, substitute_domain: substitute_domain)
            expect(downstream_response.cookies[downstream_domain_cookie_name][:domain]).to eq('example.org')
          end
        end
      end
    end
  end
end
