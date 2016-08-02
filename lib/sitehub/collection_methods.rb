class SiteHub
  module CollectionMethods
    def collection(hash, item)
      hash[item] || []
    end

    def collection!(hash, item)
      return hash[item] if hash[item]
      raise ConfigError, "missing: #{item}"
    end
  end
end
