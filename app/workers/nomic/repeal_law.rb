module Workers
  module Nomic
    class RepealLaw < Base
      def perform(post_id, law_number)
        post = Post.find_by(id: post_id)
        if post
          law_to_repeal = ::Nomic::Law.find_by(rule_number: law_number)
          if law_to_repeal
            if law_to_repeal.superseding_law
              invalid_post_response = "This is an automated reply by the Nomic bot.\n\nThe post seems to attempt to repeal a law. However, the rule that it tries to repeal is superseded by rule #{law_to_repeal.superseding_law.rule_number}. Please repeal that law or its children."
              User.find_by(id: 1).comment!(status_message, invalid_post_response)
            else
              poll_answers = post.poll.poll_answers
              yes_count = poll_answers.find_by(answer: "Yes").vote_count
              no_count = poll_answers.find_by(answer: "No").vote_count
              if yes_count > no_count
                law_to_repeal.repeal
                pass_response = "This proposal is accepted with a vote of #{yes_count} to #{no_count}. Rule #{law_to_repeal.rule_number} has been repealed."
                User.find_by(id: 1).comment!(post, pass_response)
              else
                fail_response = "This proposal is rejected with a vote of #{yes_count} to #{no_count}."
                User.find_by(id: 1).comment!(post, fail_response)
              end
            end
          else
            invalid_post_response = "This is an automated reply by the Nomic bot.\n\nThe post seems to attempt to repeal a law. However, the rule that it tries to repeal does not exist or is already repealed."
            User.find_by(id: 1).comment!(status_message, invalid_post_response)
          end
        end
      end
    end
  end
end
