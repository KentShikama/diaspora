class NomicProcessor
  ALLOWED_STARTS = %w(ENACT REPEAL AMEND TRANSMUTATE INVOKE ARBITRARY)

  def initialize(status_message, poll_present)
    text = status_message.text
    if text.starts_with?(*ALLOWED_STARTS)
      process_nomic_post(status_message, poll_present)
    else
      invalid_post_response = "This is an automated reply by the Nomic bot.\n\nThis is not a valid nomic post. If you are participating please see rule 100. If you have posted to the 'Nomic' aspect by mistake, make sure you uncheck the 'Nomic' aspect before making a post next time."
      User.find_by(id: 1).comment!(status_message, invalid_post_response)
    end
  end

  def process_nomic_post(status_message, poll_present)
    text = status_message.text
    if text.starts_with?("INVOKE")
      # Invoke judgement post processing
    elsif text.starts_with?("ARBITRARY")
      # Arbitrary post processing
    else
      if poll_present
        invalid_post_response = "This is an automated reply by the Nomic bot.\n\nThis is not a valid nomic post. Please see rule 106."
        User.find_by(id: 1).comment!(status_message, invalid_post_response)
      else
        validate_post(status_message)
      end
    end
  end

  def validate_post(status_message)
    text = status_message.text
    if text.starts_with? "ENACT"
      match = text.gsub('“','"').gsub('”','"').match(/^ENACT "([^"]*)"/)
      if match
        build_and_save_poll(status_message)
        Workers::Nomic::EnactLaw.perform_at(5.minutes.from_now, status_message.id)
      else
        invalid_post_response = "This is an automated reply by the Nomic bot.\n\nThe post seems to attempt to enact a new law. However, no written description of the law in quotes in the proper format according to Rule 106 was provided."
        User.find_by(id: 1).comment!(status_message, invalid_post_response)
      end
    elsif text.starts_with? "REPEAL"
      match = text.match(/^REPEAL (\d+)/)
      if match
        law_number = match.captures.first.to_i
        law_to_repeal = Nomic::Law.find_by(rule_number: law_number)
        if law_to_repeal && law_to_repeal.mutable
          if law_to_repeal.superseding_law
            invalid_post_response = "This is an automated reply by the Nomic bot.\n\nThe post seems to attempt to repeal a law. However, the rule that it tries to repeal is superseded by rule #{law_to_repeal.superseding_law.rule_number}. Please repeal that law or its children."
            User.find_by(id: 1).comment!(status_message, invalid_post_response)
          else
            build_and_save_poll(status_message)
            Workers::Nomic::RepealLaw.perform_at(5.minutes.from_now, status_message.id, law_number)
          end
        else
          invalid_post_response = "This is an automated reply by the Nomic bot.\n\nThe post seems to attempt to repeal a law. However, the rule that it tries to repeal does not exist, is already repealed, or is immutable."
          User.find_by(id: 1).comment!(status_message, invalid_post_response)
        end
      else
        invalid_post_response = "This is an automated reply by the Nomic bot.\n\nThe post seems to attempt to repeal a law. However, the post was not made in the proper format according to Rule 106."
        User.find_by(id: 1).comment!(status_message, invalid_post_response)
      end
    elsif text.starts_with? "AMEND"
      match = text.gsub('“','"').gsub('”','"').match(/^AMEND (\d+) to "([^"]*)"/)
      if match && match.captures.length == 2
        law_number = match.captures.first.to_i
        law_to_amend = Nomic::Law.find_by(rule_number: law_number)
        if law_to_amend && law_to_amend.mutable
          if law_to_amend.superseding_law
            invalid_post_response = "This is an automated reply by the Nomic bot.\n\nThe post seems to attempt to amend a law. However, the rule that it tries to amend is superseded by rule #{law_to_amend.superseding_law.rule_number}. Please amend that law or its children."
            User.find_by(id: 1).comment!(status_message, invalid_post_response)
          else
            build_and_save_poll(status_message)
            Workers::Nomic::AmendLaw.perform_at(5.minutes.from_now, status_message.id, law_number)
          end
        else
          invalid_post_response = "This is an automated reply by the Nomic bot.\n\nThe post seems to attempt to amend a law. However, the rule that it tries to amend does not exist, is already repealed, or is immutable."
          User.find_by(id: 1).comment!(status_message, invalid_post_response)
        end
      else
        invalid_post_response = "This is an automated reply by the Nomic bot.\n\nThe post seems to attempt to amend a law. However, the post was not made in the proper format according to Rule 106."
        User.find_by(id: 1).comment!(status_message, invalid_post_response)
      end
    elsif text.starts_with? "TRANSMUTATE"
      match = text.match(/^TRANSMUTATE (\d+) from (\w+) to (\w+)/)
      if match && match.captures.length == 3
        law_number = match.captures.first.to_i
        law_to_transmutate = Nomic::Law.find_by(rule_number: law_number)
        mutate_to = match.captures.third
        if law_to_transmutate && law_to_transmutate.mutable != (mutate_to == "MUTABLE")
          if law_to_transmutate.superseding_law
            invalid_post_response = "This is an automated reply by the Nomic bot.\n\nThe post seems to attempt to transmutate a law. However, the rule that it tries to repeal is superseded by rule #{law_to_transmutate.superseding_law.rule_number}. Please transmutate that law or its children."
            User.find_by(id: 1).comment!(status_message, invalid_post_response)
          else
            build_and_save_poll(status_message)
            Workers::Nomic::TransmutateLaw.perform_at(5.minutes.from_now, status_message.id, law_number)
          end
        else
          invalid_post_response = "This is an automated reply by the Nomic bot.\n\nThe post seems to attempt to transmutate a law. However, the rule that it tries to transmutate does not exist or has already been repealed."
          User.find_by(id: 1).comment!(status_message, invalid_post_response)
        end
      else
        invalid_post_response = "This is an automated reply by the Nomic bot.\n\nThe post seems to attempt to transmutate a law. However, the post was not made in the proper format according to Rule 106."
        User.find_by(id: 1).comment!(status_message, invalid_post_response)
      end
    else
      raise NotImplementedError # Should not be possible
    end
  end

  def build_and_save_poll(status_message)
    status_message.build_poll(question: "Do you agree with this proposal?")
    status_message.poll.poll_answers.build(answer: "Yes")
    status_message.poll.poll_answers.build(answer: "No")
    status_message.save
  end
end
