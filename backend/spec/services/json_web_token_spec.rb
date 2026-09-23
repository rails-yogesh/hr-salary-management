require "rails_helper"

RSpec.describe JsonWebToken do
  describe ".encode / .decode" do
    it "round-trips a payload" do
      token = described_class.encode(admin_user_id: 42)

      expect(described_class.decode(token)).to include("admin_user_id" => 42)
    end

    it "returns nil for a tampered token" do
      token = described_class.encode(admin_user_id: 42)

      expect(described_class.decode("#{token}garbage")).to be_nil
    end

    it "returns nil for an expired token" do
      token = described_class.encode({ admin_user_id: 42 }, 1.hour.ago)

      expect(described_class.decode(token)).to be_nil
    end

    it "returns nil for garbage input" do
      expect(described_class.decode("not-a-jwt")).to be_nil
    end
  end
end
