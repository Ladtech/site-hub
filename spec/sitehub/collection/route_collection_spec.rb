require 'sitehub/collection/route_collection'

class SiteHub
  describe Collection::RouteCollection do
    let(:collection_entry) do
      Class.new do
        include Rules, Resolver

        def initialize(rule = nil)
          @rule = rule
        end
      end
    end

    let(:route_without_rule) { collection_entry.new }

    it 'is a collection' do
      expect(subject).to be_a(Collection)
    end

    describe '#add' do
      it 'stores a value' do
        subject.add :id, route_without_rule
        expect(subject[:id]).to be(route_without_rule)
      end
    end

    describe '#valid?' do
      context 'route added' do
        it 'returns true' do
          subject.add :id, route_without_rule
          expect(subject).to be_valid
        end
      end

      context 'no routes added' do
        it 'returns false' do
          expect(subject).to_not be_valid
        end
      end
    end

    describe '#resolve' do
      context 'no rule on route' do
        it 'returns the route' do
          route_without_rule = collection_entry.new
          subject.add(:id, route_without_rule)
          expect(subject.resolve({})).to be(route_without_rule)
        end
      end
      context 'rule on route' do
        it 'passes the environment to the rule' do
          request_env = {}
          rule = proc { |env| env[:env_passed_in] = true }

          proxy = collection_entry.new
          proxy.rule(rule)
          subject.add(:id, proxy)
          subject.resolve(env: request_env)
          expect(request_env[:env_passed_in]).to eq(true)
        end

        context 'rule applies' do
          it 'returns the route' do
            route_with_rule = collection_entry.new(proc { true })
            subject.add(:id, route_with_rule)
            expect(subject.resolve({})).to be(route_with_rule)
          end
        end

        context 'rule does not apply' do
          it 'returns nil' do
            route_with_rule = collection_entry.new(proc { false })
            subject.add(:id, route_with_rule)
            expect(subject.resolve({})).to eq(nil)
          end
        end
      end
    end
  end
end
