## Caching

CalInvite supports flexible caching options when used within a Rails application. You can configure the cache store to use any of Rails' supported cache stores including memory store, Redis, or a custom cache store implementation.

### Basic Configuration

Configure caching in your Rails application's initializer:

```ruby
# config/initializers/cal_invite.rb
CalInvite.configure do |config|
  # Use Rails.cache by default
  config.cache_store = Rails.cache
  
  # Optional: Set a custom prefix for cache keys
  config.cache_prefix = 'my_app_cal_invite'
  
  # Optional: Set cache expiration (in seconds)
  config.cache_expires_in = 3600 # 1 hour
end
```

### Available Cache Stores

CalInvite supports the following cache stores:

1. Memory Store (default)
```ruby
config.cache_store = :memory_store
```

2. Null Store (for disabling caching)
```ruby
config.cache_store = :null_store
```

3. Custom Cache Store
```ruby
# Any object that implements read/write/delete methods
config.cache_store = MyCacheStore.new
```

4. Rails Cache
```ruby
# Use your Rails application's configured cache
config.cache_store = Rails.cache
```

### Cache Configuration Options

- `cache_store`: The storage mechanism for cached data
- `cache_prefix`: Prefix for all cache keys (default: 'cal_invite')
- `cache_expires_in`: Default cache expiration time in seconds
- `timezone`: Default timezone for cache keys (default: 'UTC')

### Custom Cache Adapters

You can implement custom cache adapters by creating a class that responds to the following methods:

```ruby
class CustomCacheStore
  def read(key)
    # Implementation for retrieving cached value
  end

  def write(key, value, options = {})
    # Implementation for storing value in cache
    # options may include :expires_in
  end

  def delete(key)
    # Implementation for removing cached value
  end

  def clear
    # Implementation for clearing all cached values
  end
end

# Configure CalInvite to use your custom cache store
CalInvite.configure do |config|
  config.cache_store = CustomCacheStore.new
end
```

### Automatic Cache Invalidation

The cache is automatically invalidated in the following scenarios:

1. When event attributes are updated via `update_attributes`
2. When a new calendar URL is generated
3. When the configuration changes

### Best Practices

1. **Cache Store Selection**: Choose an appropriate cache store based on your needs:
   - Use `:memory_store` for development and small applications
   - Use Rails.cache for production applications
   - Implement a custom cache store for specific requirements

2. **Cache Key Management**:
   - The gem automatically generates unique cache keys based on event attributes
   - Keys include a prefix for namespace isolation
   - Consider your timezone settings when debugging cache issues

3. **Expiration Strategy**:
   - Set appropriate expiration times based on your use case
   - Consider using shorter expiration times for frequently changing data
   - Use `nil` expiration for permanent caching (until manual invalidation)

### Example Rails Integration

Here's a complete example of setting up caching in a Rails application:

```ruby
# config/initializers/cal_invite.rb
CalInvite.configure do |config|
  if Rails.env.production?
    # Use Rails cache in production
    config.cache_store = Rails.cache
    config.cache_expires_in = 1.hour
  else
    # Use memory store in development
    config.cache_store = :memory_store
    config.cache_expires_in = 5.minutes
  end

  config.cache_prefix = "cal_invite:#{Rails.env}"
  config.timezone = 'UTC'
end
```

### Testing with Caching

When writing tests that involve caching:

```ruby
# In your test setup
CalInvite.configure do |config|
  config.cache_store = :memory_store
  config.cache_expires_in = 3600 # 1 hour in seconds
end

# Clear cache between tests
def setup
  CalInvite.configuration.cache_store.clear
end
```