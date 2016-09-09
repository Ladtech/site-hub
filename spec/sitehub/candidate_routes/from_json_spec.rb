class SiteHub
  class CandidateRoutes
    describe FromJson do
      describe '::from_hash' do
        include_context :sitehub_json

        let(:described_class){CandidateRoutes}

        context 'splits' do
          subject do
            described_class.from_hash(split_proxy, :expected)
          end
          context 'sitehub_cookie_name' do
            it 'sets it' do
              expect(subject.sitehub_cookie_name).to eq(:expected)
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
            expected = described_class.new(sitehub_cookie_name: :expected,
                                           sitehub_cookie_path: subject.sitehub_cookie_path,
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
          subject do
            described_class.from_hash(routes_proxy, :expected)
          end
          context 'sitehub_cookie_name' do
            it 'sets it' do
              expect(subject.sitehub_cookie_name).to eq(:expected)
            end
          end

          context 'sitehub_cookie_path' do
            it 'sets it' do
              expect(subject.sitehub_cookie_path).to eq(routes_proxy[:sitehub_cookie_path])
            end
          end

          it 'returns core with routes' do
            route_1 = route_1()
            expected = described_class.new(sitehub_cookie_name: :expected,
                                           sitehub_cookie_path: subject.sitehub_cookie_path,
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
            subject do
              described_class.from_hash(nested_route_proxy, :expected)
            end

            it 'creates them' do
              route_1 = route_1()
              nested_route = nested_route()

              expected = described_class.new(sitehub_cookie_name: :expected,
                                             sitehub_cookie_path: subject.sitehub_cookie_path,
                                             mapped_path: subject.mapped_path) do
                split(percentage: nested_route[:percentage], label: nested_route[:label]) do
                  route label: route_1[:label], url: route_1[:url]
                end
              end
              expect(subject).to eq(expected)
            end
          end

          context 'splits in a split' do
            subject do
              described_class.from_hash(nested_split_proxy, :expected)
            end

            it 'creates them' do
              split_1 = split_1()
              split_2 = split_2()
              nested_split = nested_split()

              expected = described_class.new(sitehub_cookie_name: :expected,
                                             sitehub_cookie_path: subject.sitehub_cookie_path,
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
          #TODO - implement me
          it 'sets the default' do
          end
        end
      end
    end
  end
end