# SiteHub
[![CircleCI](https://circleci.com/gh/lvl-up/sitehub.svg?style=shield&circle-token=da10bde2f25581f01839fb7078fc2a098a98ca13)](https://circleci.com/gh/lvl-up/sitehub)

SiteHub is a HTTP proxy written in Ruby with support for A|B testing baked in. SiteHub sits in front of your web application(s) routing all HTTP traffics between it and your users. 

Wouldn't it be cool to write something like: 
```ruby
sitehub = SiteHub.build do 
  proxy %r{/catalogue/(.*)} do
    split percentage: 50, url: 'http://version1.com/$1', label: :prototype_1
    split percentage: 50, url: 'http://version2.com/$1', label: :prototype_2
  end
end

run sitehub
```
or 
```ruby
user_eligible = proc{} #perform check and return boolean

sitehub = SiteHub.build do 
  proxy %r{/catalogue/(.*)} do
    route url: 'http://new_catalogue.com/catalogue/$1', label: :new_version, rule: user_eligbile 
    
    default url: 'http://current_catalogue.com/$1'
  end
  # other proxy definitions ...
end

run sitehub
```

With SiteHub you can:
- A|B testing new features
- Silently release new features - SiteHub can be used to put a new version of you application live but inaccessible to users. This new version can still be accessed by teams to peform final checks before opening up the new version to the public.
- Modular Web Applications - SiteHub can be used to front discrete applications and present a unified root.

## Installation
`gem install sitehub`

## Definning a SiteHub
A SiteHub is a rack application so needs to be passed to the `run` method in your rackup file

example config.ru
```ruby
require 'sitehub'
sitehub = SiteHub.build do
  proxy '/' => 'http://downstream.url.com'
end
run sitehub
```

## Defining proxies
Proxies can have either routes or splits defined within them but not both at the same time.
- Splits - define the percentage chance that a downstream url will be used to proxy a user request.
- Routes - routes are defined with a rule that determines whether or not a user request can be sent to its downstream url

### Version affinity
Once a downstream route has been chosen for a given route it is sticky. Meaning that users will stay with a version and not flip flop between them.

Sitehub does this by dropping a cookie that holds the route version that a request is sent to.

By default the cookie will be given the name `sitehub.recorded_route` and will have the path of the request.

#### Overiding the name
This is done at the top level of your sitehub definition. The name you supply will be used for all sitehub cookies dropped by all proxies.
```ruby
sitehub = SiteHub.build do
  sitehub_cookie_name :your_custom_name
end
```

#### Overiding the path
This is done a proxy by proxy basis
```ruby
sitehub = SiteHub.build do
  proxy '/' do
    sitehub_cookie_path '/your/path'
    #splits/routes defined here
  end
end
```
**Caution:** 
By default sitehub is going to use the path of the request. If you have used a regular expression to define a proxy, this will be different for each unique request that is made.

e.g. for the following example, calls to /path1, and /path2 would each be given a cookie meaning that users could flip between different version for the same proxy definition. In this case you are definately going to want to set the `sitehub_cookie_path` to keep things consistent.

```ruby
sitehub = SiteHub.build do
  proxy %r{/*} do
    #splits/routes defined here
  end
end
```

### Routes with Rules
Define a route inside a proxy defintion as follows
```ruby
sitehub = SiteHub.build do 
  proxy '/catalogue' do
    route url: 'http://new_catalogue.com/catalogue', label: :new_version, rule: user_eligbile
    # ...
  end
end
```
Rules must be an object that responds to call with a single parameter that returns a boolean. True means that the rule applies and false means that it does not.

The parameter passed to call is the request environment hash. This lets you write things like:
```ruby
has_special_parameter = proc do |env|
  Rack::Request.new(env).params.include?(:special_param)
end
```

### Splits
Splits are defined as follows
```ruby
sitehub = SiteHub.build do 
  proxy '/catalogue' do
    split percentage: 50, url: 'http://version1.com', label: :prototype_1
    split percentage: 50, url: 'http://version2.com', label: :prototype_2
  end
end
```
Split percentages must add up to 100% unless a default is defined.

### Default routes
When defining either Splits or Routes a default can be defined. Defaults are used as a fallback if a route with a rule that applies can't be found or a split can't be chosen on the first time of trying (This can happen when the splits don't add up to 100%).
```ruby
sitehub = SiteHub.build do 
  proxy '/catalogue' do
    route url: 'http://new_catalogue.com/catalogue', label: :new_version, rule: a_rule
    default url: 'http://current_catalogue.com'
  end
end
```
### Nesting routes and splits
Routes and Splits can themselves contain further route or split definitions
```ruby
sitehub = SiteHub.build do 
  proxy '/catalogue' do
    # Experiment 1
    split(precentage: 30) do
      # 30% of overall traffic is split between 2 different prototypes
      split percentage: 50, url: 'http://version1.com', label: :prototype_1
      split percentage: 50, url: 'http://version2.com', label: :prototype_2
    end
    
    # Experiment 2
    split(precentage: 30) do
      # 30% of overall traffic is split between 2 different prototypes
      split percentage: 50, url: 'http://version3.com', label: :prototype_3
      split percentage: 50, url: 'http://version4.com', label: :prototype_4
    end
  
    default url: 'http://current_catalogue.com'
  end
end
```
### Labels
Splits and Routes must be defined with a label. Within a proxy defintion, this label must be unique. This is the value that SiteHub will use to identify the version of a downstream url that a user should stick to once it has been selected.

### Matching
Proxy can be defined to capture specific paths using a literal string or be defined to have a broader appeal using regexs
```ruby
sitehub = SiteHub.build do 
  proxy '/catalogue' => 'http://downstream.catalogue.com'
  proxy %r{/orders/*} => 'http://downstream.orders.com'
end
```

### Substitution
Portions of the request path can be captured and passed downstream by specifying capture groups your path regular expression.
```ruby
sitehub = SiteHub.build do 
  proxy %r{'/orders/(.*)} => 'http://downstream.orders.com/$1'
end
```

## Using middleware
You can `use` middleware in conjunction with a particular proxy definition or the SiteHub as a whole. 
### Proxy specifc middleware
```ruby
sitehub = SiteHub.build do 
  proxy '/catalogue/(.*)' do
    use AuthenticationMiddlware
  end
end
```
In this example, only requests received by the proxy definition will be made to go through the AuthenticationMiddleware

### SiteHub wide middlware
```ruby
sitehub = SiteHub.build do 
  use AuthenticationMiddleware
  proxy '/catalogue' => 'http://downstream.catalogue.com'
  proxy '/orders' => 'http://downstream.orders.com'
end
```
In this example, all requests handled by the SiteHub will go through the AuthenticationMiddleware
### Reverse Proxying
In order to ensure that you applications stay firmly behind your SiteHub, you are going need to ensure that any responses that they return have are rewritten to remove references to your downstream URLs. SiteHub does this for the `Location` header (set for redirects) and will soon do it for the [Content-Location](https://github.com/bskyb-commerce/sitehub/issues/8) header also.
```ruby
sitehub = SiteHub.build do
  proxy %r{/orders/(.*)} => 'http://downstream.orders.com/$1'
  reverse_proxy %r{http://downstream.orders.com/(.*)} => '/orders/$1'
end
```
*Note* The above example also performs substitution from the downstream URL in to the upstream mapping. This is not mandatory

## SiteHub Transaction ID
SiteHub introduces a custom header to downstream requests called `sitehub_transaction_id` that is unique to every request. The idea is that if a request is made from the downstream system to another then this header should be passed on also. If access/errors in each system are logged along with this id, then tracing things in distributed systems will become easier.

The transaction id, if passed on through out, could also be used for request scoped caching.

## Logging
By default SiteHub will log requests and errors to STDOUT and STDERR respectively. You can overide this with your own logging devices. For example you may want to send requests and errors to syslog. Just make sure that your logger object responds to `<<` or `write` and SiteHub will do the rest.
```ruby
sitehub = SiteHub.build do
  access_logger YourLogger.new
  error_logger YourLogger.new
end
```
