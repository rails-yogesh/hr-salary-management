module SeedData
  # Picks a key from a { key => weight } hash proportionally to its weight.
  # Used to give the seed data a realistic shape (e.g. a headcount pyramid
  # with more juniors than directors) instead of a uniform distribution.
  module Weighted
    def self.sample(weights)
      total = weights.values.sum
      point = rand(total)
      cumulative = 0

      weights.each do |key, weight|
        cumulative += weight
        return key if point < cumulative
      end

      weights.keys.last
    end
  end
end
