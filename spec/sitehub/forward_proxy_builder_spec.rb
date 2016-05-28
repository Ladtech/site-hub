# rubocop:disable Metrics/ClassLength
require 'sitehub/forward_proxy_builder'

class SiteHub
  describe ForwardProxyBuilder do
    include_context :middleware_test

    subject do
      described_class.new(mapped_path: '/path')
    end

    it 'supports middleware' do
      expect(described_class).to include(Middleware)
    end

    describe '#initialize' do
      context 'with a block' do
        it 'evaluates the block in the context of the instance' do
          self_inside_block = nil
          instance = described_class.new(url: '/app1', mapped_path: '/path') { self_inside_block = self }
          expect(self_inside_block).to eq(instance)
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
      context 'duplicate label used' do
        it 'raises an error' do
          subject.split percentage: 10, url: :url, label: :label

          expect { subject.split percentage: 10, url: :url, label: :label }
            .to raise_exception(Collection::DuplicateVersionException, 'supply unique labels')
        end
      end

      context 'split supplied' do
        context 'block supplied' do
          it 'stores a forward proxy builder' do
            proc = proc do
              default url: :url
            end

            subject.split(percentage: 50, &proc)

            expected_builder = described_class.new(mapped_path: subject.mapped_path, &proc)
            expected_split = SiteHub::Collection::SplitRouteCollection::Split.new(0, 50, expected_builder)
            expect(subject.endpoints.values).to eq([expected_split])
          end
        end

        context 'block not supplied' do
          it 'stores a split for the version' do
            subject.split url: :url, label: :label, percentage: 50

            expected_proxy = { ForwardProxy.new(url: :url, id: :label, sitehub_cookie_name: :cookie_name) => 50 }
            expected = Collection::SplitRouteCollection.new(expected_proxy)

            expect(subject.endpoints).to eq(expected)
          end

          context 'label not supplied' do
            it 'raises an error' do
              expect { subject.split(url: :url, percentage: 50) }
                .to raise_error(ForwardProxyBuilder::InvalidDefinitionException)
            end
          end

          context 'url not supplied' do
            it 'raises an error' do
              expect { subject.split(label: :label, percentage: 50) }
                .to raise_error(ForwardProxyBuilder::InvalidDefinitionException)
            end
          end
        end
      end

      context 'routes defined' do
        it 'throws and error' do
          subject.route url: :url, label: :label

          expect { subject.split(url: :url, label: :label, percentage: 50) }
            .to raise_error(ForwardProxyBuilder::InvalidDefinitionException)
        end
      end
    end

    describe 'route' do
      it 'accepts a rule' do
        subject.route url: :url, label: :current, rule: :rule
        expected_route = ForwardProxy.new(url: :url, id: :current, rule: :rule, sitehub_cookie_name: :cookie_name)
        expect(subject.endpoints).to eq(expected_route.id => expected_route)
      end

      context 'block supplied' do
        context 'rule not supplied' do
          it 'raise an error' do
            expected_message = described_class::INVALID_ROUTE_DEF_MSG
            expect { subject.route {} }.to raise_exception described_class::InvalidDefinitionException, expected_message
          end
        end

        it 'stores a proxy builder' do
          rule = proc { true }
          proc = proc do
            route url: :url, label: :label1
          end

          subject.route(rule: rule, &proc)

          expected_builder = described_class.new(mapped_path: subject.mapped_path, &proc)
          expect(subject.endpoints.values).to eq([expected_builder])
        end

        context 'invalid definitions inside block' do
          it 'raises an error' do
            rule = proc { true }
            expect do
              subject.route rule: rule do
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
          subject.route url: :url, label: :current, rule: rule
          proxy_before_build = subject.endpoints[:current]
          subject.build
          proxy_after_build = subject.endpoints[:current]
          expect(proxy_after_build).to be(proxy_before_build)
          expect(proxy_after_build.rule).to be(rule)
        end

        it 'does not extend the endpoint with Resolver' do
          subject.route url: :url, label: :current, rule: rule
          expect(subject.endpoints[:current]).to_not receive(:extend).with(Resolver)
          subject.build
        end
      end

      context 'middleware specified' do
        before do
          subject.use middleware
          subject.route url: :url, label: :current, rule: rule
        end

        it 'wraps the forward proxies in the middleware' do
          proxy_before_build = subject.endpoints[:current]

          subject.build
          proxy_after_build = subject.endpoints[:current]
          expect(proxy_after_build).to be_a(middleware)
          expect(proxy_after_build.app).to be(proxy_before_build)
        end

        it 'extends the middleware with Resolver' do
          subject.build
          expect(subject.endpoints[:current]).to be_a(Resolver)
        end

        it 'extends the middleware with Rules' do
          subject.build
          expect(subject.endpoints[:current]).to be_a(Rules)
        end

        context 'rule on route' do
          it 'adds it to the rule to the middleware object' do
            subject.build
            expect(subject.endpoints[:current].rule).to eq(rule)
          end
        end

        it 'wraps the default in the middleware' do
          subject.default url: :url
          default_proxy_before_build = subject.default_proxy

          subject.build
          default_proxy_after_build = subject.default_proxy
          expect(default_proxy_after_build).to be_a(middleware)
          expect(default_proxy_after_build.app).to be(default_proxy_before_build)
        end
      end
    end
    describe '#resolve' do
      subject { described_class.new(mapped_path: '/') }

      context 'routes defined' do
        it 'returns that route' do
          subject.route url: :url, label: :current
          expect(subject.resolve(env: {})).to eq(subject.endpoints.values.first)
        end

        it 'passes the env to the when resolving the correct route' do
          expect_any_instance_of(subject.routes.class).to receive(:resolve).with(env: :env).and_call_original
          subject.resolve(env: :env)
        end
      end

      context 'splits defined' do
        it 'serves an entry from the routes' do
          subject.split(percentage: 100, url: :url, label: :label)
          expect(subject.endpoints).to receive(:resolve).and_return(:pick)
          expect(subject.resolve(env: {})).to eq(:pick)
        end

        context 'splits not defined' do
          it 'returns the default' do
            subject.default url: :url
            expect(subject.resolve(env: {})).to eq(subject.default_proxy)
          end
        end
      end

      context 'endpoints' do
        context 'called with a collection' do
          it 'sets endpoints to be that collection' do
            subject.endpoints(:collection)
            expect(subject.endpoints).to eq(:collection)
          end
        end

        context 'already set with a different collection' do
          it 'raise an error' do
            subject.endpoints(:collection1)
            expect { subject.endpoints(:collection2) }.to raise_exception described_class::InvalidDefinitionException
          end
        end
      end

      context 'version selected' do
        context 'version applies to a route' do
          before do
            subject.split percentage: 50, url: :url1, label: :new
            subject.split percentage: 50, url: :url2, label: :old
          end

          let(:application_version1) do
            subject.endpoints.values.find do |pick|
              pick.value.id == :new
            end.value
          end

          context 'string supplied' do
            it 'redirects to that version' do
              expect(subject.resolve(id: :new.to_s, env: {})).to eq(application_version1)
            end
          end

          context 'symbol supplied' do
            it 'redirects to that version' do
              expect(subject).to_not receive(:auto_resolve)
              expect(subject.resolve(id: :new, env: {})).to eq(application_version1)
            end
          end
        end
      end
    end

    describe '#forward_proxy' do
      subject do
        described_class.new(mapped_path: '/path', sitehub_cookie_name: :expected_cookie_name)
      end

      it 'sets the sitehub_cookie_path' do
        subject.sitehub_cookie_path :cookie_path
        proxy = subject.forward_proxy(label: :label, url: :url)
        expect(proxy.sitehub_cookie_path).to eq(:cookie_path)
      end

      it 'sets the sitehub_cookie_name' do
        proxy = subject.forward_proxy(label: :label, url: :url)
        expect(proxy.sitehub_cookie_name).to eq(:expected_cookie_name)
      end
    end
  end
end
