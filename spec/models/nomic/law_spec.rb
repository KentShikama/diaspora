#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require "spec_helper"

describe Nomic::Law, type: :model do
  let!(:superseding_mutable_law) { FactoryGirl.create(:superseding_mutable_law) }

  describe "#go down and up history chain" do
    it "is successful" do
      superseded_law = superseding_mutable_law.superseded_law
      expect(superseded_law).to_not be_nil
      superseding_law = superseded_law.superseding_law
      expect(superseding_law).to eq(superseding_mutable_law)
    end
  end

  describe "#repeal" do
    it "repeals superseded laws" do
      superseding_mutable_law.repeal
      expect(superseding_mutable_law.repealed).to eq(true)
      expect(superseding_mutable_law.superseded_law.repealed).to eq(true)
    end
  end

  describe "#automiatc rule generation" do
    it "is successful" do
      new_law = Nomic::Law.create!(text: "Law #301", mutable: false, author: FactoryGirl.create(:person))
      expect(new_law.rule_number).to eq(301)
    end
  end

  describe "#retrieve author" do
    it "is successful" do
      new_law = Nomic::Law.create!(text: "Law #301", mutable: false, author: bob.person)
      expect(new_law.author.diaspora_handle.starts_with? "bob").to be(true)
    end
  end
end
