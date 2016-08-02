# rubocop:disable Metrics/ClassLength
require 'sitehub/candidate_routes'

class SiteHub
  describe CandidateRoutes do
    include_context :middleware_test

    describe '::from_hash' do
      include_context :sitehub_json

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
        it 'sets the default' do
        end
      end
    end

    subject do
      described_class.new(sitehub_cookie_name: :cookie_name,
                          mapped_path: '/path')
    end

    describe '#routes' do
      it 'returns RouteCollection by default' do
        expect(subject.candidates).to be_a(Collection::RouteCollection)
      end

      it 'returns the same intance everytime' do
        collection = Collection::SplitRouteCollection.new
        subject.candidates(collection)
        expect(subject.candidates).to be(collection)
      end

      context 'endpoints already set' do
        context 'different object supplied' do
          it 'raises an error' do
            subject.candidates(Collection::SplitRouteCollection.new)
            expect { subject.candidates(Collection::RouteCollection.new) }
              .to raise_error(CandidateRoutes::InvalidDefinitionException)
          end
        end
      end
    end

    describe '#[]' do
      context 'id of existing route passed in' do
        it 'returns it' do
          subject.split(label: :current, percentage: 100, url: :url)
          expect(subject[:current]).to eq(subject[:current])
        end
      end
    end

    it 'supports middleware' do
      expect(described_class).to include(Middleware)
    end

    describe '#initialize' do
      let(:named_parameters) do
        { sitehub_cookie_name: :name,
          mapped_path: '/path' }
      end

      context 'with a block' do
        it 'evaluates the block in the context of the instance' do
          self_inside_block = nil
          instance = described_class.new(named_parameters) do
            self_inside_block = self
            default(url: :url)
          end
          expect(self_inside_block).to eq(instance)
        end
      end

      context 'id' do
        context 'id supplied' do
          it 'sets the id using it' do
            subject = described_class.new(named_parameters.merge(id: :custom_id))
            expect(subject.id).to eq(:custom_id)
          end
        end
      end
    end

    describe 'valid?' do
      context 'default defined' do
        context 'splits add up to 100' do
          it 'returns true' do
            subject.split(percentage: 100, label: :old, url: :url)
            expect(subject.valid?).to eq(true)
          end
        end

        context 'splits do not add up to 100' do
          it 'returns true' do
            subject.split(percentage: 10, label: :old, url: :url)
            subject.default(url: :url)
            expect(subject.valid?).to eq(true)
          end
        end
      end

      context 'default not defined' do
        context 'splits add up to 100' do
          it 'returns true' do
            subject.default(url: :url)
            expect(subject.valid?).to eq(true)
          end
        end

        context 'splits do not add up to 100' do
          it 'returns false' do
            subject.split(percentage: 10, label: :old, url: :url)
            subject.split(percentage: 10, label: :new, url: :url)
            expect(subject).to_not be_valid
          end
        end
      end
    end

    describe '#split' do
      it 'setups up a splits collection' do
        subject.split percentage: 10, url: :url, label: :label
        expect(subject.candidates).to be_a(Collection::SplitRouteCollection)
      end
    end

    describe '#route' do
      it 'sets up the routes collection' do
        subject.route url: :url, label: :current
        expect(subject.candidates).to be_a(Collection::RouteCollection)
      end
    end

    describe '#add' do
      it 'stores the route against the given label' do
        subject.add url: :url, label: :current

        proxy = ForwardProxy.new(mapped_url: :url,
                                 mapped_path: subject.mapped_path)

        expected_route = Route.new(proxy,
                                   id: :current,
                                   sitehub_cookie_name: :cookie_name,
                                   sitehub_cookie_path: nil)

        expect(subject[:current]).to eq(expected_route)
      end

      it 'accepts a rule' do
        endpoint = subject.add url: :url, label: :current, rule: :rule
        expect(endpoint.rule).to eq(:rule)
      end

      it 'accepts a percentage' do
        subject.candidates(Collection::SplitRouteCollection.new)
        endpoint = subject.add url: :url, label: :current, percentage: 50
        expect(endpoint.upper).to eq(50)
      end

      context 'block supplied' do
        let(:block) do
          proc do
            route url: :url, label: :label2, rule: :rule do
              route url: :url, label: :label3
            end
          end
        end

        it 'stores the nested route_builder against the label' do
          rule = proc { true }
          subject.add(rule: rule, label: :label1, &block)
          subject.use middleware

          expected_endpoints = CandidateRoutes.new(rule: rule,
                                                   id: :label1,
                                                   sitehub_cookie_name: :cookie_name,
                                                   mapped_path: '/path',
                                                   &block).build

          expect(subject[:label1]).to eq(expected_endpoints)
          subject.build
        end

        describe '#errors and warnings' do
          context 'precentage and rule not supplied' do
            context 'split required' do
              it 'raise an error' do
                subject.candidates(Collection::SplitRouteCollection.new)
                expected_message = described_class::PERCENTAGE_NOT_SPECIFIED_MSG
                expect { subject.add(label: :label) {} }
                  .to raise_exception described_class::InvalidDefinitionException, expected_message
              end
            end

            context 'route required' do
              it 'raise an error' do
                subject.candidates(Collection::RouteCollection.new)
                expected_message = described_class::RULE_NOT_SPECIFIED_MSG
                expect { subject.add(label: :label) {} }
                  .to raise_exception described_class::InvalidDefinitionException, expected_message
              end
            end
          end

          context 'url' do
            it 'gives a warning to say that the url will not be used' do
              expect(subject).to receive(:warn).with(described_class::IGNORING_URL_MSG)
              subject.add(rule: :rule, url: :url, label: :label, &block)
            end
          end
        end

        it 'stores a proxy builder' do
          rule = proc { true }
          subject.add(rule: rule, label: :label, &block)

          expected_endpoints = described_class.new(id: :label, sitehub_cookie_name: :cookie_name,
                                                   rule: rule, mapped_path: subject.mapped_path, &block).tap do |builder|
            builder.sitehub_cookie_name subject.sitehub_cookie_name
          end.build

          expect(subject.candidates.values).to eq([expected_endpoints])
        end

        context 'invalid definitions inside block' do
          it 'raises an error' do
            rule = proc { true }
            expect do
              subject.add rule: rule, label: :label do
                split percentage: 20, url: :url, label: :label1
              end
            end.to raise_exception described_class::InvalidDefinitionException
          end
        end
      end
    end

    describe '#build' do
      let(:rule) { proc {} }

      context 'middleware not specified' do
        it 'leaves it the proxies alone' do
          subject.route url: :url, label: :current
          expect(subject[:current]).to be_using_rack_stack(ForwardProxy)
          subject.build
          expect(subject[:current]).to be_using_rack_stack(ForwardProxy)
        end
      end

      context 'middleware specified' do
        before do
          subject.use middleware
        end

        it 'wraps the forward proxies in the middleware' do
          subject.route url: :url, label: :current
          subject.build
          expect(subject[:current]).to be_using_rack_stack(middleware, ForwardProxy)
        end

        it 'wraps the default in the middleware' do
          subject.default url: :url
          subject.build
          expect(subject.default_route).to be_using_rack_stack(middleware, ForwardProxy)
        end
      end

      context 'middleware present on the parent route' do
        it 'adds it to the list middleware to be added' do
          middleware = middleware()
          subject.split(percentage: 100, label: :parent) do
            use middleware
            split(percentage: 100, label: :child) do
              default url: :url
            end
          end
          expect(subject[:parent][:child].default_route).to be_using(middleware)
        end
      end
    end

    describe '#resolve' do
      context 'id not supplied' do
        context 'routes defined' do
          it 'returns that route' do
            subject.route url: :url, label: :current
            expect(subject.resolve(env: {})).to eq(subject.candidates.values.first)
          end

          it 'passes the env to the when resolving the correct route' do
            expect_any_instance_of(subject.candidates.class).to receive(:resolve).with(env: :env).and_call_original
            subject.resolve(env: :env)
          end
        end

        context 'splits not defined' do
          it 'returns the default' do
            subject.default url: :url
            expect(subject.resolve(env: {})).to eq(subject.default_route)
          end
        end
      end

      context 'id supplied' do
        context 'nested routes' do
          let!(:expected) do
            result = nil
            subject.split percentage: 0, label: :experiment1 do
              result = split percentage: 100, url: :url1, label: :new
            end
            subject.split percentage: 100, label: :experiment2, url: :url
            result.value
          end

          it 'returns that route' do
            expect(subject.resolve(id: expected.id, env: {})).to eq(expected)
          end
        end

        context 'id does not exist' do
          let!(:expected) do
            subject.default url: :url
            subject.default_route
          end

          it 'returns the default route' do
            expect(subject.resolve(id: :missing, env: {})).to eq(expected)
          end
        end

        context 'non nested route' do
          let!(:expected) do
            subject.split(percentage: 100, label: :experiment1, url: :url).value
          end

          it 'returns that route' do
            expect(subject.resolve(id: expected.id, env: {})).to eq(expected)
          end
        end
      end
    end

    context '#endpoints' do
      context 'called with a collection' do
        it 'sets endpoints to be that collection' do
          subject.candidates(:collection)
          expect(subject.candidates).to eq(:collection)
        end
      end

      context 'already set with a different collection' do
        it 'raise an error' do
          subject.candidates(:collection1)
          expect { subject.candidates(:collection2) }.to raise_exception described_class::InvalidDefinitionException
        end
      end
    end

    describe '#forward_proxy' do
      subject do
        described_class.new(sitehub_cookie_name: :cookie_name,
                            mapped_path: '/path')
      end

      it 'sets the sitehub_cookie_path' do
        subject.sitehub_cookie_path :cookie_path
        proxy = subject.forward_proxy(label: :label, url: :url)
        expect(proxy.sitehub_cookie_path).to eq(:cookie_path)
      end

      it 'sets the sitehub_cookie_name' do
        subject.sitehub_cookie_name :expected_cookie_name
        proxy = subject.forward_proxy(label: :label, url: :url)
        expect(proxy.sitehub_cookie_name).to eq(:expected_cookie_name)
      end
    end

    describe '#method_missing' do
      context 'calling scope set' do
        subject do
          calling_scope = double(:calling_scope, parent_method: :called)
          described_class.new(sitehub_cookie_name: :cookie_name,
                              mapped_path: '/path',
                              calling_scope: calling_scope)
        end
        context 'method on calling_context' do
          it 'delegates to it' do
            expect(subject.parent_method).to eq(:called)
          end
        end

        context 'method on calling_context' do
          it 'delegates to it' do
            expect(subject.parent_method).to eq(:called)
          end
        end
      end

      context 'calling scope not set' do
        it 'raises an error' do
          expect { subject.parent_method }.to raise_error(NoMethodError)
        end
      end
    end
  end
end
