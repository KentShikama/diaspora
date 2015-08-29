require "spec_helper"

describe Workers::Nomic::EnactLaw do
  describe "#create" do
    let!(:user) { FactoryGirl.create(:user_with_nomic_aspect)}
    before do
      Nomic::Law.create!(rule_number: 300, text: "Law to be repealed", author: user.person)
      @status_message = user.build_post(:status_message, {text: "ENACT \"This is the new law.\"", aspect_ids: [user.aspects.take.id], public: false})
      @status_message.build_poll(question: "Do you agree with this proposal?")
      @status_message.poll.poll_answers.build(answer: "Yes")
      @status_message.poll.poll_answers.build(answer: "No")
      @status_message.save
      user.participate_in_poll!(@status_message, PollAnswer.find_by(answer: "Yes"))
    end

    it "succeeds" do
      Workers::Nomic::EnactLaw.new.perform(@status_message.id)
      expect(Nomic::Law.where(author: user.person).second.text).to eq("This is the new law.")
    end
  end
end
