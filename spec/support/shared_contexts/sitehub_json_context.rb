shared_context :sitehub_json do
  let(:sitehub_json) do
    {
      proxies: [routes_proxy, split_proxy]
    }
  end

  let(:routes_proxy) do
    {
      path: '/route_1',
      sitehub_cookie_path: 'route_1_cookie_path',
      routes: [route_1],
      default: 'route_proxy_default_url'
    }
  end

  let(:split_proxy) do
    {
      path: '/route_2',
      sitehub_cookie_path: 'route_2_cookie_path',
      splits: [split_1, split_2],
      default: 'split_proxy_default_url'
    }
  end

  let(:nested_split_proxy) do
    {
      path: '/route_3',
      sitehub_cookie_path: 'route_3_cookie_path',
      splits: [nested_split],
      default: 'route_proxy_default_url'
    }
  end

  let(:nested_route_proxy) do
    {
      path: '/route_3',
      sitehub_cookie_path: 'route_3_cookie_path',
      splits: [nested_route],
      default: 'route_proxy_default_url'
    }
  end

  let(:nested_split) do
    {
      label: :nested_split_label,
      percentage: 100,
      splits: [split_1, split_2]
    }
  end

  let(:nested_route) do
    {
      label: :nested_route_label,
      percentage: 100,
      routes: [route_1]
    }
  end

  let(:route_1) do
    {
      label: :route_label_1,
      url: 'http://lvl-up.uk/'
    }
  end

  let(:split_1) do
    {
      label: :split_label_1,
      url: 'http://lvl-up.uk/',
      percentage: 50
    }
  end

  let(:split_2) do
    {
      label: :split_label_2,
      url: 'http://lvl-up.uk/',
      percentage: 50
    }
  end
end
