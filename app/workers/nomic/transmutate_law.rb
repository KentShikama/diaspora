module Workers
  module Nomic
    class TransmutateLaw < Base
      def perform(post_id, law_number)
        post = Post.find_by(id: post_id)
        if post
          law_to_mutate = ::Nomic::Law.find_by(rule_number: law_number)
          if law_to_mutate
            if law_to_mutate.superseding_law
              invalid_post_response = "This is an automated reply by the Nomic bot.\n\nThe post seems to attempt to transmutate a law. However, the rule that it tries to transmutate is superseded by rule #{law_to_mutate.superseding_law.rule_number}. Please transmutate that law or its children."
              User.find_by(id: 1).comment!(status_message, invalid_post_response)
            else
              poll_answers = post.poll.poll_answers
              yes_count = poll_answers.find_by(answer: "Yes").vote_count
              no_count = poll_answers.find_by(answer: "No").vote_count
              if yes_count > no_count
                new_law = ::Nomic::Law.create!(author: post.author, text: law_to_mutate.text, mutable: !law_to_mutate.mutable, superseded_law: law_to_mutate)
                mutable_state_string = new_law.mutable ? "Mutable" : "Immutable"
                pass_response = "This proposal is accepted with a vote of #{yes_count} to #{no_count}. Rule #{law_to_mutate.rule_number} has been transmutated to #{mutable_state_string} and is now rule #{new_law.rule_number}."
                User.find_by(id: 1).comment!(post, pass_response)
              else
                fail_response = "This proposal is rejected with a vote of #{yes_count} to #{no_count}."
                User.find_by(id: 1).comment!(post, fail_response)
              end
            end
          else
            invalid_post_response = "This is an automated reply by the Nomic bot.\n\nThe post seems to attempt to transmutate a law. However, the rule that it tries to transmutate does not exist or is already repealed."
            User.find_by(id: 1).comment!(status_message, invalid_post_response)
          end
        end
      end
    end
  end
end
