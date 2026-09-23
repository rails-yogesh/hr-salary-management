require "rails_helper"

RSpec.describe Department, type: :model do
  subject { build(:department) }

  it { is_expected.to be_valid }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to have_many(:employees) }
end
