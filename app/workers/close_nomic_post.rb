module Workers
  class CloseNomicPost < Base
    def perform(post_id)
      post = Post.find_by(id: post_id)
      poll_answers = post.poll.poll_answers
      yes_count = poll_answers.find_by(answer: "Yes").vote_count
      no_count = poll_answers.find_by(answer: "No").vote_count
      if yes_count > no_count
        pass_response = "This proposal is accepted with a vote of #{yes_count} to #{no_count}."
        User.find_by(id: 1).comment!(post, pass_response)
      else
        fail_response = "This proposal is rejected with a vote of #{yes_count} to #{no_count}."
        User.find_by(id: 1).comment!(post, fail_response)
      end
    end
  end
end
