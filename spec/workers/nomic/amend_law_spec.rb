require "spec_helper"

describe Workers::Nomic::AmendLaw do
  describe "#create" do
    let!(:user) { FactoryGirl.create(:user_with_nomic_aspect)}
    before do
      Nomic::Law.create!(rule_number: 300, text: "Law to be amended", author: user.person)
      @status_message = user.build_post(:status_message, {text: "AMEND 300 to \"This law has been amended\"", aspect_ids: [user.aspects.take.id], public: false})
      @status_message.build_poll(question: "Do you agree with this proposal?")
      @status_message.poll.poll_answers.build(answer: "Yes")
      @status_message.poll.poll_answers.build(answer: "No")
      @status_message.save
      user.participate_in_poll!(@status_message, PollAnswer.find_by(answer: "Yes"))
    end

    it "succeeds" do
      Workers::Nomic::AmendLaw.new.perform(@status_message.id, 300)
      expect(Nomic::Law.where(author: user.person).second.text).to eq("This law has been amended")
    end
  end
end
