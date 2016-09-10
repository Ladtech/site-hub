class SiteHub
  class CandidateRoutes
    describe FromJson do
      describe '::from_hash' do
        include_context :sitehub_json

        let(:described_class) { CandidateRoutes }
        subject { described_class.from_hash(proxy_config, :top_level_cookie_name, :top_level_cookie_path) }

        context 'cookie configuration' do
          let(:cookie_name) { 'custom_name' }
          let(:cookie_path) { 'custom_path' }

          context 'no config defined on proxy' do
            let(:proxy_config) do
              {
                path: '/',
                default: 'url'
              }
            end

            it 'uses the config passed in to the method' do
              expect(subject.default_route.sitehub_cookie_name).to eq(:top_level_cookie_name)
              expect(subject.default_route.sitehub_cookie_path).to eq(:top_level_cookie_path)
            end
          end

          context 'defined on proxy' do
            let(:proxy_config) do
              {
                path: '/',
                sitehub_cookie_name: cookie_name,
                sitehub_cookie_path: cookie_path,
                default: 'url'
              }
            end

            it 'uses the configuration' do
              expect(subject.default_route.sitehub_cookie_name).to eq(cookie_name)
              expect(subject.default_route.sitehub_cookie_path).to eq(cookie_path)
            end

            # TODO: - support cookie config within split
            # context 'config defined on split' do
            #   let(:proxy_config_hash) do
            #     {
            #         path: '/',
            #         splits: [
            #             {sitehub_cookie_path: cookie_path,
            #              sitehub_cookie_name: cookie_name,
            #              percentage: 100,
            #              url: 'url',
            #              label: 'route_label'}
            #         ]
            #     }
            #   end
            #   it 'is overidden by the config on the route' do
            #     expect(subject.sitehub_cookie_name).to eq(cookie_name)
            #     expect(subject.sitehub_cookie_path).to eq(cookie_path)
            #   end
            # end
          end

          # TODO: - support cookie config within split
          context 'defined on route' do
            it 'uses the configuration' do
            end
          end
        end

        context 'splits' do
          let(:proxy_config) { split_proxy }

          context 'sitehub_cookie_name' do
            it 'sets it' do
              expect(subject.sitehub_cookie_name).to eq(:top_level_cookie_name)
            end
          end

          context 'sitehub_cookie_path' do
            it 'sets it' do
              expect(subject.sitehub_cookie_path).to eq(split_proxy[:sitehub_cookie_path])
            end
          end

          it 'returns core with splits' do
            split_1 = split_1()
            split_2 = split_2()
            expected = described_class.new(version_cookie: TrackingCookieDefinition.new(:top_level_cookie_name, subject.sitehub_cookie_path),
                                           mapped_path: subject.mapped_path) do
              split percentage: split_1[:percentage], label: split_1[:label], url: split_1[:url]
              split percentage: split_2[:percentage], label: split_2[:label], url: split_2[:url]
            end
            expect(subject.candidates).to eq(expected.candidates)
          end

          context 'default' do
            it 'sets it' do
              expect(subject.default_route.app.mapped_url).to eq(split_proxy[:default])
            end
          end
        end

        context 'routes' do
          let(:proxy_config) { routes_proxy }

          context 'sitehub_cookie_name' do
            it 'sets it' do
              expect(subject.sitehub_cookie_name).to eq(:top_level_cookie_name)
            end
          end

          context 'sitehub_cookie_path' do
            it 'sets it' do
              expect(subject.sitehub_cookie_path).to eq(routes_proxy[:sitehub_cookie_path])
            end
          end

          it 'returns core with routes' do
            route_1 = route_1()
            expected = described_class.new(version_cookie: TrackingCookieDefinition.new(:top_level_cookie_name, subject.sitehub_cookie_path),
                                           mapped_path: subject.mapped_path) do
              route label: route_1[:label], url: route_1[:url]
            end
            expect(subject.candidates).to eq(expected.candidates)
          end

          context 'default' do
            it 'sets it' do
              expect(subject.default_route.app.mapped_url).to eq(routes_proxy[:default])
            end
          end
        end

        context 'nested routes' do
          context 'routes inside a split' do
            let(:proxy_config) { nested_route_proxy }
            it 'creates them' do
              route_1 = route_1()
              nested_route = nested_route()

              expected = described_class.new(version_cookie: TrackingCookieDefinition.new(:top_level_cookie_name, subject.sitehub_cookie_path),
                                             mapped_path: subject.mapped_path) do
                split(percentage: nested_route[:percentage], label: nested_route[:label]) do
                  route label: route_1[:label], url: route_1[:url]
                end
              end
              expect(subject).to eq(expected)
            end
          end

          context 'splits in a split' do
            let(:proxy_config) { nested_split_proxy }

            it 'creates them' do
              split_1 = split_1()
              split_2 = split_2()
              nested_split = nested_split()

              expected = described_class.new(version_cookie: TrackingCookieDefinition.new(:top_level_cookie_name, subject.sitehub_cookie_path),
                                             mapped_path: subject.mapped_path) do
                split(percentage: nested_split[:percentage], label: nested_split[:label]) do
                  split percentage: split_1[:percentage], label: split_1[:label], url: split_1[:url]
                  split percentage: split_2[:percentage], label: split_2[:label], url: split_2[:url]
                end
              end
              expect(subject).to eq(expected)
            end
          end
        end

        context 'default' do
          let(:default_url) { 'url' }
          let(:proxy_config_default) do
            {
              path: '/',
              default: default_url
            }
          end

          subject do
            described_class.from_hash(proxy_config_default, :expected, :top_level_cookie_path)
          end

          it 'sets the default url' do
            expect(subject.default_route.app.mapped_url).to eq(default_url)
          end
        end
      end
    end
  end
end
