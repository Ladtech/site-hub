shared_context :sitehub_json do
  let(:sitehub_json) do
    {
      proxies: [proxy_1, proxy_2]
    }
  end

  let(:proxy_1) do
    {
      path: '/route_1',
      sitehub_cookie_path: 'route_1_cookie_path',
      routes: [route_1]
    }
  end

  let(:proxy_2) do
    {
      path: '/route_1',
      sitehub_cookie_path: 'route_1_cookie_path',
      splits: [split_1, split_2]
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
