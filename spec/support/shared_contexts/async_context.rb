require_relative '../async'
shared_context :async do
  def callback
    @callback ||= Async::Callback.new
  end

  def async_response_handler
    @async_response_handler = Async::ResponseHandler.new
  end

  def last_response
    app.last_response
  end
end
