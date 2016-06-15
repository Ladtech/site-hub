shared_context :module_spec do
  subject do
    Object.new.tap do |object|
      object.extend(described_class)
    end
  end
end
