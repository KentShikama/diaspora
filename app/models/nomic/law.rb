module Nomic
  class Law < ActiveRecord::Base
    has_one :superseding_law, class_name: "Law", foreign_key: :superseded_law_id
    belongs_to :superseded_law, class_name: "Law"
    belongs_to :author, class_name: "Person"

    validates :rule_number, presence: true, uniqueness: true
    validates :author, presence: true
    validates :text, presence: true
    validates_inclusion_of :mutable, in: [true, false]
    validates_inclusion_of :repealed, in: [true, false]

    before_validation :setup, on: :create

    def setup
      maximum = [Nomic::Law.maximum("rule_number"), 300].max if Nomic::Law.maximum("rule_number")
      self.rule_number ||= (maximum ? maximum : 300) + 1
    end

    def repeal
      if superseded_law
        superseded_law.repealed = true
        superseded_law.save
      end
      self.repealed = true
      save
    end
  end
end
