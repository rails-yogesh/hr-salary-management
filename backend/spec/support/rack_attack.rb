# Rack::Attack's counters live in a process-wide MemoryStore
# (config/initializers/rack_attack.rb) that persists across examples —
# without resetting it, an earlier example's login attempts count toward
# a later example's throttle window, since the whole suite runs in well
# under the 20-second throttle period.
RSpec.configure do |config|
  config.before do
    Rack::Attack.cache.store.clear
  end
end
