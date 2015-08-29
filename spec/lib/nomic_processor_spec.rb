require "spec_helper"

describe NomicProcessor do
  let!(:user) { FactoryGirl.create(:user_with_nomic_aspect)}
  describe "#nomic" do
    describe "#random post" do
      it "succeeds" do
        status_message = user.build_post(:status_message, {text: "Hey everyone", aspect_ids: [user.aspects.take.id], public: false})
        NomicProcessor.new(status_message, true)
        expect(status_message.comments.take.text).to eq("This is an automated reply by the Nomic bot.\n\nThis is not a valid nomic post. If you are participating please see rule 100. If you have posted to the 'Nomic' aspect by mistake, make sure you uncheck the 'Nomic' aspect before making a post next time.")
      end
    end

    describe "#random post with poll" do
      it "succeeds" do
        status_message = user.build_post(:status_message, {text: "ENACT \"This is the new law.\"", aspect_ids: [user.aspects.take.id], public: false})
        NomicProcessor.new(status_message, true)
        expect(status_message.comments.take.text).to eq("This is an automated reply by the Nomic bot.\n\nThis is not a valid nomic post. Please see rule 106.")
      end
    end

    describe "#enact" do
      it "succeeds" do
        status_message = user.build_post(:status_message, {text: "ENACT \"This is the new law.\"", aspect_ids: [user.aspects.take.id], public: false})
        status_message.save
        expect(Workers::Nomic::EnactLaw).to receive(:perform_at)
        NomicProcessor.new(status_message, false)
        expect(Poll.find_by(status_message_id: status_message.id)).to_not be_nil
      end
    end

    describe "#repeal" do
      it "succeeds" do
        Nomic::Law.create!(rule_number: 300, text: "Law to be repealed", author: user.person)
        status_message = user.build_post(:status_message, {text: "REPEAL 300", aspect_ids: [user.aspects.take.id], public: false})
        status_message.save
        expect(Workers::Nomic::RepealLaw).to receive(:perform_at)
        NomicProcessor.new(status_message, false)
        expect(Poll.find_by(status_message_id: status_message.id)).to_not be_nil
      end
    end

    describe "#amend" do
      it "succeeds" do
        Nomic::Law.create!(rule_number: 300, text: "Law to be repealed", author: user.person)
        status_message = user.build_post(:status_message, {text: "AMEND 300 to \"Hello world\"", aspect_ids: [user.aspects.take.id], public: false})
        status_message.save
        expect(Workers::Nomic::AmendLaw).to receive(:perform_at)
        NomicProcessor.new(status_message, false)
        expect(Poll.find_by(status_message_id: status_message.id)).to_not be_nil
      end
    end

    describe "#transmutate" do
      it "succeeds" do
        Nomic::Law.create!(rule_number: 300, text: "Law to be repealed", author: user.person)
        status_message = user.build_post(:status_message, {text: "TRANSMUTATE 300 from MUTABLE to IMMUTABLE", aspect_ids: [user.aspects.take.id], public: false})
        status_message.save
        expect(Workers::Nomic::TransmutateLaw).to receive(:perform_at)
        NomicProcessor.new(status_message, false)
        expect(Poll.find_by(status_message_id: status_message.id)).to_not be_nil
      end
    end
  end
end
