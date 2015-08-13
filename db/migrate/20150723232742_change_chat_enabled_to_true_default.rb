class ChangeChatEnabledToTrueDefault < ActiveRecord::Migration
  def self.up
    remove_column :aspects, :chat_enabled
    add_column :aspects, :chat_enabled, :boolean, default: true
  end

  def self.down
    remove_column :aspects, :chat_enabled
    add_column :aspects, :chat_enabled, :boolean, default: false
  end
end
