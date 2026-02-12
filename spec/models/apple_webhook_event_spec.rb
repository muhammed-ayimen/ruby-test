require "rails_helper"

RSpec.describe AppleWebhookEvent, type: :model do
  describe "validations" do
    subject { build(:apple_webhook_event) }

    it { is_expected.to validate_presence_of(:notification_uuid) }
    it { is_expected.to validate_uniqueness_of(:notification_uuid) }
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_presence_of(:transaction_id) }
  end

  describe "#processed!" do
    it "updates processing_status to processed" do
      event = create(:apple_webhook_event)
      event.processed!
      expect(event.reload.processing_status).to eq("processed")
    end
  end

  describe "#failed!" do
    it "updates processing_status to failed with error message" do
      event = create(:apple_webhook_event)
      event.failed!("Something went wrong")
      event.reload
      expect(event.processing_status).to eq("failed")
      expect(event.error_message).to eq("Something went wrong")
    end
  end

  describe "scopes" do
    it ".pending returns events with pending status" do
      pending_event = create(:apple_webhook_event, processing_status: "pending")
      create(:apple_webhook_event, processing_status: "processed")

      expect(AppleWebhookEvent.pending).to eq([pending_event])
    end

    it ".failed returns events with failed status" do
      create(:apple_webhook_event, processing_status: "pending")
      failed_event = create(:apple_webhook_event, processing_status: "failed")

      expect(AppleWebhookEvent.failed).to eq([failed_event])
    end
  end
end
