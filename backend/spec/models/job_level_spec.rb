require "rails_helper"

RSpec.describe JobLevel, type: :model do
  subject { build(:job_level) }

  it { is_expected.to be_valid }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to validate_presence_of(:rank) }
  it { is_expected.to validate_uniqueness_of(:rank) }
  it { is_expected.to have_many(:employees) }

  it "orders by rank by default" do
    low = create(:job_level, rank: 5)
    high = create(:job_level, rank: 1)

    expect(JobLevel.all).to eq([high, low])
  end
end
