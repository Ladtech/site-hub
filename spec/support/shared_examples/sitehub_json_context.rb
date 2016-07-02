shared_context :sitehub_json do
  let(:sitehub_json) do
    {
        proxies: [
            {
                path: '/route_1',
                routes: [
                    {
                        label: :label_1,
                        url: 'http://lvl-up.uk/'
                    }
                ]
            }
        ]
    }
  end
end