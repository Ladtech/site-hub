shared_examples 'a memoized helper' do
  it 'returns the same instance every time' do
    method = self.class.parent_groups[1].description.delete('#')
    first_result = subject.send(method)
    expect(first_result).to be(subject.send(method))
  end
end
