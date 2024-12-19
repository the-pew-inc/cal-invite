## Caching

CalInvite supports flexible caching options when used within a Rails application. You can configure the cache store to use any of Rails' supported cache stores including memory store, Redis, Memcached, or Active Record.

### Basic Configuration

Configure caching in your Rails application's initializer:

```ruby
# config/initializers/cal_invite.rb
CalInvite.configure do |config|
  # Use Rails.cache by default
  config.cache_store = Rails.cache
  
  # Optional: Set a custom prefix for cache keys
  config.cache_prefix = 'my_app_cal_invite'
end
```

### Available Cache Stores

CalInvite supports all cache stores available in Rails:

1. Memory Store (default)
```ruby
config.cache_store = :memory_store
```

2. Redis Cache Store
```ruby
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  namespace: 'cal_invite'
}
```

3. Memcached
```ruby
config.cache_store = :mem_cache_store, 'localhost:11211'
```

4. Active Record (using your database)
```ruby
config.cache_store = :active_record_store
```

### Cache Management

CalInvite provides several methods to manage the cache:

```ruby
# Clear all CalInvite caches
CalInvite.clear_cache!

# Clear cache for a specific event
CalInvite.clear_event_cache!(event_id)

# Clear cache for a specific provider
CalInvite.clear_provider_cache!(provider_name)

# Get cached value
CalInvite.fetch_from_cache(key) { yield }

# Write to cache with optional expiration
CalInvite.write_to_cache(key, value, expires_in: 1.hour)
```

### Cache Key Generation

CalInvite uses a standardized format for cache keys:

```ruby
# Format: "#{prefix}:#{scope}:#{identifier}"
cache_key = CalInvite.generate_cache_key('events', event_id)
```

### Automatic Cache Invalidation

The cache is automatically invalidated in the following scenarios:

1. When an event is updated
2. When provider configurations change
3. When the gem version is updated

You can also set up automatic cache expiration:

```ruby
CalInvite.configure do |config|
  config.cache_store = Rails.cache
  config.cache_prefix = 'cal_invite'
  config.cache_expires_in = 24.hours # Default cache expiration
end
```

### Custom Cache Adapters

You can implement custom cache adapters by creating a class that responds to the following methods:

```ruby
class CustomCacheStore
  def read(key)
    # Implementation
  end

  def write(key, value, options = {})
    # Implementation
  end

  def delete(key)
    # Implementation
  end

  def clear
    # Implementation
  end
end

# Configure CalInvite to use your custom cache store
CalInvite.configure do |config|
  config.cache_store = CustomCacheStore.new
end
```

### Best Practices

1. **Cache Keys**: Use meaningful and unique cache keys to avoid collisions:
```ruby
cache_key = "#{CalInvite.configuration.cache_prefix}:events:#{event.id}:#{provider}"
```

2. **Cache Expiration**: Set appropriate expiration times based on your needs:
```ruby
CalInvite.write_to_cache(key, value, expires_in: 12.hours)
```

3. **Cache Warming**: Implement cache warming for frequently accessed events:
```ruby
# In a background job
frequently_accessed_events.each do |event|
  CalInvite::Providers::SUPPORTED_PROVIDERS.each do |provider|
    event.generate_calendar_url(provider)
  end
end
```

4. **Monitoring**: Monitor cache hit rates and adjust caching strategy accordingly:
```ruby
# Add instrumentation
ActiveSupport::Notifications.subscribe("cache_read.cal_invite") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  # Log or track cache metrics
end
```

### Rails Integration Example

Here's a complete example of setting up caching in a Rails application:

```ruby
# config/initializers/cal_invite.rb
CalInvite.configure do |config|
  if Rails.env.production?
    # Use Redis in production
    config.cache_store = :redis_cache_store, {
      url: ENV['REDIS_URL'],
      namespace: 'cal_invite',
      expires_in: 12.hours
    }
  else
    # Use memory store in development
    config.cache_store = :memory_store
  end

  config.cache_prefix = "cal_invite:#{Rails.env}"
end

# Add cache sweepers if needed
ActiveSupport::Notifications.subscribe("cal_invite.cache.invalidate") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  # Perform additional cache invalidation logic
end
```